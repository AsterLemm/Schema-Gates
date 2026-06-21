// =====================================================================
//  cpu_arm16.v
//  16-bit ARM-FLAVOURED CPU: full conditional execution (NZCV),
//  3-operand data processing, inline barrel shifter on operand 2,
//  S-bit flag writes, ARM carry convention (SUB sets C = no-borrow),
//  BL/BX subroutine linkage through r14. 32-bit Harvard instructions
//  on imem_*; 32-word data RAM. See docs/cpus.md for the encoding.
//  MODULAR: cond / decode / shifter / ALU(arith+logic) / regfile /
//  dmem / flags submodules give a DigitalJS-style drillable hierarchy.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- cpu_arm16_cond : ARM condition check (gates EVERY instruction) ---
module cpu_arm16_cond(
    input  wire [3:0] cond,
    input  wire       fN,
    input  wire       fZ,
    input  wire       fC,
    input  wire       fV,
    output reg        cond_pass
);
    always @(*) begin case (cond)
        4'd0:  cond_pass = fZ;               // EQ
        4'd1:  cond_pass = ~fZ;              // NE
        4'd2:  cond_pass = fC;               // CS/HS
        4'd3:  cond_pass = ~fC;              // CC/LO
        4'd4:  cond_pass = fN;               // MI
        4'd5:  cond_pass = ~fN;              // PL
        4'd6:  cond_pass = fV;               // VS
        4'd7:  cond_pass = ~fV;              // VC
        4'd8:  cond_pass = fC & ~fZ;         // HI
        4'd9:  cond_pass = ~fC | fZ;         // LS
        4'd10: cond_pass = (fN == fV);       // GE
        4'd11: cond_pass = (fN != fV);       // LT
        4'd12: cond_pass = ~fZ & (fN == fV); // GT
        4'd13: cond_pass = fZ | (fN != fV);  // LE
        4'd14: cond_pass = 1'b1;             // AL
        default: cond_pass = 1'b0;           // NV (never)
    endcase end
endmodule

// --- cpu_arm16_decode : field extraction + condition-gated class decode ---
module cpu_arm16_decode(
    input  wire [31:0] ir,
    input  wire        cond_pass,
    output wire [3:0]  cond,
    output wire        sbit,
    output wire [1:0]  cls,
    output wire [3:0]  op4,
    output wire [3:0]  rd,
    output wire [3:0]  rn,
    output wire [3:0]  rm,
    output wire [1:0]  shtyp,
    output wire [4:0]  shamt,
    output wire [7:0]  imm8,
    output wire [16:0] imm17,
    output wire        is_dp,
    output wire        is_mem,
    output wire        is_flow,
    output wire        is_test,
    output wire        wr_flag,
    output wire        is_b,
    output wire        is_bl,
    output wire        is_bx,
    output wire        is_outi,
    output wire        is_hlt,
    output wire        is_ldr,
    output wire        is_str,
    output wire        sel_arith,
    output wire        sel_logic,
    output wire        dp_wr
);
    // ---- field extraction ---------------------------------------------
    assign cond  = ir[31:28];
    assign sbit  = ir[27];
    assign cls   = ir[26:25];
    assign op4   = ir[24:21];
    assign rd    = ir[20:17];
    assign rn    = ir[16:13];
    assign rm    = ir[12:9];
    assign shtyp = ir[8:7];
    assign shamt = ir[6:2];
    assign imm8  = ir[12:5];
    assign imm17 = ir[16:0];

    assign is_dp   = cond_pass & (cls[1] == 1'b0);
    assign is_mem  = cond_pass & (cls == 2'b10);
    assign is_flow = cond_pass & (cls == 2'b11);
    assign is_test = (op4 >= 4'd12);               // CMP CMN TST TEQ
    assign wr_flag = is_dp & (sbit | is_test);

    assign sel_arith = is_dp & ((op4 >= 4'd2 & op4 <= 4'd6) |
                              (op4 == 4'd12) | (op4 == 4'd13)); // SUB..SBC CMP CMN
    assign sel_logic = is_dp & ~sel_arith;
    assign dp_wr = is_dp & ~is_test;

    // ---- flow + memory --------------------------------------------------
    assign is_b    = is_flow & (op4 == 4'd0);
    assign is_bl   = is_flow & (op4 == 4'd1);
    assign is_bx   = is_flow & (op4 == 4'd2);
    assign is_outi = is_flow & (op4 == 4'd3);
    assign is_hlt  = is_flow & (op4 == 4'd4);
    assign is_ldr  = is_mem & ~op4[0];
    assign is_str  = is_mem &  op4[0];
endmodule

// --- cpu_arm16_shifter : inline barrel shifter on operand 2 ---
// (operand-isolated: only live for register-form data processing)
module cpu_arm16_shifter(
    input  wire [15:0] rmv,
    input  wire [4:0]  shamt,
    input  wire [1:0]  shtyp,
    input  wire        sh_en,
    input  wire        fC,
    output reg  [15:0] sh_out,
    output reg         sh_cout
);
    wire [15:0] sh_in = rmv & {16{sh_en}};
    wire [4:0]  sh_n  = shamt & {5{sh_en}};
    // rotate uses the amount modulo W; shifts saturate naturally
    always @(*) begin
        case (shtyp)
            2'd0: begin                                     // LSL
                sh_out  = sh_in << sh_n;
                sh_cout = (sh_n == 5'd0) ? fC
                        : (sh_n <= 5'd16) ? sh_in[16-sh_n] : 1'b0;
            end
            2'd1: begin                                     // LSR
                sh_out  = sh_in >> sh_n;
                sh_cout = (sh_n == 5'd0) ? fC
                        : (sh_n <= 5'd16) ? sh_in[sh_n-5'd1] : 1'b0;
            end
            2'd2: begin                                     // ASR
                sh_out  = $signed(sh_in) >>> sh_n;
                sh_cout = (sh_n == 5'd0) ? fC
                        : (sh_n <= 5'd16) ? sh_in[sh_n-5'd1] : sh_in[15];
            end
            default: begin                                  // ROR
                sh_out  = (sh_in >> sh_n[3:0]) | (sh_in << (16 - sh_n[3:0]));
                sh_cout = (sh_n == 5'd0) ? fC : sh_out[15];
            end
        endcase
    end
endmodule

// --- cpu_arm16_alu_arith : unified A+B+cin adder, ARM C/V convention ---
// (leaf of cpu_arm16_alu)
module cpu_arm16_alu_arith(
    input  wire [15:0] aa,
    input  wire [15:0] ab,
    input  wire [3:0]  op4,
    input  wire        fC,
    output wire [15:0] ar_y,
    output wire        ar_c,
    output wire        ar_v
);
    // unified adder: A + B + cin with operand inversion per op
    //   ADD: A=rn  B=op2  cin=0      ADC: cin=C
    //   SUB/CMP: B=~op2 cin=1        SBC: B=~op2 cin=C
    //   RSB: A=~rn B=op2 cin=1       CMN: like ADD
    wire inv_a = (op4 == 4'd3);                       // RSB
    wire inv_b = (op4 == 4'd2) | (op4 == 4'd6) | (op4 == 4'd12); // SUB SBC CMP
    wire cin   = (op4 == 4'd2) | (op4 == 4'd3) | (op4 == 4'd12) ? 1'b1
               : (op4 == 4'd5) | (op4 == 4'd6)                  ? fC
               : 1'b0;
    wire [15:0] adA = inv_a ? ~aa : aa;
    wire [15:0] adB = inv_b ? ~ab : ab;
    wire [16:0] adS = {1'b0, adA} + {1'b0, adB} + {{16{1'b0}}, cin};
    assign ar_y = adS[15:0];
    assign ar_c = adS[16];                 // ARM: C = NOT borrow on subtract
    assign ar_v = (adA[15] == adB[15]) & (ar_y[15] != adA[15]);
endmodule

// --- cpu_arm16_alu_logic : AND/EOR/ORR/MOV/MVN/BIC + TST/TEQ (leaf of cpu_arm16_alu) ---
module cpu_arm16_alu_logic(
    input  wire [15:0] la,
    input  wire [15:0] lb,
    input  wire [3:0]  op4,
    output reg  [15:0] lg_y
);
    always @(*) begin case (op4)
        4'd0, 4'd14: lg_y = la & lb;        // AND TST
        4'd1, 4'd15: lg_y = la ^ lb;        // EOR TEQ
        4'd7:        lg_y = la | lb;        // ORR
        4'd9:        lg_y = ~lb;            // MVN
        4'd10:       lg_y = la & ~lb;       // BIC
        default:     lg_y = lb;             // MOV (8, 11)
    endcase end
endmodule

// --- cpu_arm16_alu : data-processing ALU (operand-isolated arith + logic) ---
module cpu_arm16_alu(
    input  wire [15:0] rnv,
    input  wire [15:0] op2,
    input  wire [3:0]  op4,
    input  wire        fC,
    input  wire        sel_arith,
    input  wire        sel_logic,
    output wire [15:0] dp_y,
    output wire        ar_c,
    output wire        ar_v
);
    wire [15:0] aa = rnv & {16{sel_arith}};
    wire [15:0] ab = op2 & {16{sel_arith}};
    wire [15:0] ar_y;
    cpu_arm16_alu_arith u_arith(.aa(aa), .ab(ab), .op4(op4), .fC(fC),
                          .ar_y(ar_y), .ar_c(ar_c), .ar_v(ar_v));

    wire [15:0] la = rnv & {16{sel_logic}};
    wire [15:0] lb = op2 & {16{sel_logic}};
    wire [15:0] lg_y;
    cpu_arm16_alu_logic u_logic(.la(la), .lb(lb), .op4(op4), .lg_y(lg_y));

    assign dp_y = sel_arith ? ar_y : lg_y;
endmodule

// --- cpu_arm16_regfile : 16x16 register file, r14 = LR by convention ---
// single write port: DP result / LDR data / BL link are mutually
// exclusive by instruction class, so one muxed port carries all three.
module cpu_arm16_regfile(
    input  wire        clk,
    input  wire        we,
    input  wire [3:0]  waddr,
    input  wire [15:0] wdata,
    input  wire [3:0]  rn,
    input  wire [3:0]  rm,
    input  wire [3:0]  rd,
    output wire [15:0] rnv,
    output wire [15:0] rmv,
    output wire [15:0] rdv,
    input  wire [3:0]  dbg_sel,
    output wire [15:0] dbg_data
);
    reg [15:0] r [0:15];        // r14 = LR by convention

    assign rnv = r[rn];
    assign rmv = r[rm];
    assign rdv = r[rd];
    assign dbg_data = r[dbg_sel];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) r[waddr] <= wdata;
    end
endmodule

// --- cpu_arm16_dmem : 32-word data RAM (sync write, async read) ---
module cpu_arm16_dmem(
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  addr,
    input  wire [15:0] wdata,
    output wire [15:0] rdata
);
    reg [15:0] dmem [0:31];

    assign rdata = dmem[addr];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) dmem[addr] <= wdata;
    end
endmodule

// --- cpu_arm16_flags : NZCV status register (ARM S-bit semantics) ---
module cpu_arm16_flags(
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [15:0] dp_y,
    input  wire        sel_arith,
    input  wire        ar_c,
    input  wire        ar_v,
    input  wire [1:0]  cls,
    input  wire        sh_cout,
    output reg         fN,
    output reg         fZ,
    output reg         fC,
    output reg         fV
);
    always @(posedge clk) begin
        if (rst) begin
            fN <= 1'b0; fZ <= 1'b0; fC <= 1'b0; fV <= 1'b0;
        end else if (we) begin
            fN <= dp_y[15];
            fZ <= (dp_y == {16{1'b0}});
            if (sel_arith) begin fC <= ar_c; fV <= ar_v; end
            else if (cls == 2'b00) fC <= sh_cout;   // logical: shifter carry
        end
    end
endmodule

module cpu_arm16(
    input  wire        clk,
    input  wire        rst,
    // Harvard instruction port (word addressed; supply ROM externally)
    output wire [7:0]  imem_addr,
    input  wire [31:0] imem_data,
    // OUT instruction port
    output reg  [15:0]  out_data,
    output reg         out_valid,
    // status / debug
    output reg         halted,
    input  wire [3:0]  dbg_sel,
    output wire [15:0]  dbg_data,
    output wire [7:0]  dbg_pc
);
    // define clk                    input   255.230.80
    // define rst                    input   255.80.80
    // define imem_addr              output  38.15.153
    // define imem_data              input   126.199.90
    // define out_data               output  120.255.160
    // define out_valid              output  97.255.239
    // define halted                 output  255.120.120
    // define dbg_sel                input   200.120.255
    // define dbg_data               output  178.54.0
    // define dbg_pc                 output  255.0.26

    reg [7:0] pc;

    // ---- NZCV flags (live in the flags unit below) -------------------
    wire fN, fZ, fC, fV;

    // ---- decode + condition check ------------------------------------
    wire [3:0]  cond, op4, rd, rn, rm;
    wire        sbit, cond_pass;
    wire [1:0]  cls, shtyp;
    wire [4:0]  shamt;
    wire [7:0]  imm8;
    wire [16:0] imm17;
    wire is_dp, is_mem, is_flow, is_test, wr_flag;
    wire is_b, is_bl, is_bx, is_outi, is_hlt, is_ldr, is_str;
    wire sel_arith, sel_logic, dp_wr;
    cpu_arm16_cond u_cond(
        .cond(cond), .fN(fN), .fZ(fZ), .fC(fC), .fV(fV),
        .cond_pass(cond_pass)
    );
    cpu_arm16_decode u_decode(
        .ir(imem_data), .cond_pass(cond_pass),
        .cond(cond), .sbit(sbit), .cls(cls), .op4(op4),
        .rd(rd), .rn(rn), .rm(rm),
        .shtyp(shtyp), .shamt(shamt), .imm8(imm8), .imm17(imm17),
        .is_dp(is_dp), .is_mem(is_mem), .is_flow(is_flow),
        .is_test(is_test), .wr_flag(wr_flag),
        .is_b(is_b), .is_bl(is_bl), .is_bx(is_bx),
        .is_outi(is_outi), .is_hlt(is_hlt),
        .is_ldr(is_ldr), .is_str(is_str),
        .sel_arith(sel_arith), .sel_logic(sel_logic),
        .dp_wr(dp_wr)
    );

    // write gating: identical condition to the old monolithic block
    // (writes happened only in the `else if (!halted)` branch).
    wire wr_gate = ~rst & ~halted;

    // ---- register file (single muxed write port) ---------------------
    wire [15:0] rnv, rmv, rdv, dmem_rd, dp_y;
    wire [15:0] linkv = {{8{1'b0}}, pc1};   // BL: r14 <= pc+1
    wire rf_we = wr_gate & (dp_wr | is_ldr | is_bl);
    wire [3:0] rf_waddr = is_bl ? 4'd14 : rd;
    wire [15:0] rf_wdata = is_bl  ? linkv
                          : is_ldr ? dmem_rd
                          :          dp_y;
    cpu_arm16_regfile u_regfile(
        .clk(clk),
        .we(rf_we), .waddr(rf_waddr), .wdata(rf_wdata),
        .rn(rn), .rm(rm), .rd(rd),
        .rnv(rnv), .rmv(rmv), .rdv(rdv),
        .dbg_sel(dbg_sel), .dbg_data(dbg_data)
    );

    // ---- barrel shifter on operand 2 ---------------------------------
    wire sh_en = is_dp & (cls == 2'b00);
    wire [15:0] sh_out;
    wire sh_cout;
    cpu_arm16_shifter u_shifter(
        .rmv(rmv), .shamt(shamt), .shtyp(shtyp),
        .sh_en(sh_en), .fC(fC),
        .sh_out(sh_out), .sh_cout(sh_cout)
    );

    // operand 2: shifted register (cls 00) or zero-extended imm8 (cls 01)
    wire [15:0] imm8w = {{8{1'b0}}, imm8};
    wire [15:0] op2 = (cls == 2'b00) ? sh_out : imm8w;

    // ---- data-processing ALU (arith + logic paths inside) ------------
    wire ar_c, ar_v;
    cpu_arm16_alu u_alu(
        .rnv(rnv), .op2(op2), .op4(op4), .fC(fC),
        .sel_arith(sel_arith), .sel_logic(sel_logic),
        .dp_y(dp_y), .ar_c(ar_c), .ar_v(ar_v)
    );

    // ---- data RAM -----------------------------------------------------
    wire [4:0] mem_a = rnv[4:0] + imm8[4:0];
    cpu_arm16_dmem u_dmem(
        .clk(clk),
        .we(wr_gate & is_str),
        .addr(mem_a), .wdata(rdv),
        .rdata(dmem_rd)
    );

    // ---- NZCV flags unit ----------------------------------------------
    cpu_arm16_flags u_flags(
        .clk(clk), .rst(rst),
        .we(wr_gate & wr_flag),
        .dp_y(dp_y), .sel_arith(sel_arith),
        .ar_c(ar_c), .ar_v(ar_v),
        .cls(cls), .sh_cout(sh_cout),
        .fN(fN), .fZ(fZ), .fC(fC), .fV(fV)
    );

    wire [7:0] btgt  = pc + imm17[7:0];         // relative, word units
    wire [7:0] pc1   = pc + 8'd1;

    assign imem_addr = pc;
    assign dbg_pc    = pc;

    // sequencing: identical to the monolithic core; the regfile, dmem
    // and flag writes moved into their modules with the same conditions.
    always @(posedge clk) begin
        out_valid <= 1'b0;
        if (rst) begin
            pc <= 8'd0; halted <= 1'b0;
            out_data <= {16{1'b0}};
        end else if (!halted) begin
            pc <= (is_b | is_bl) ? btgt
                : is_bx          ? rnv[7:0]
                : is_hlt         ? pc
                :                  pc1;
            if (is_outi) begin out_data <= rnv; out_valid <= 1'b1; end
            if (is_hlt)  halted <= 1'b1;
        end
    end
endmodule


