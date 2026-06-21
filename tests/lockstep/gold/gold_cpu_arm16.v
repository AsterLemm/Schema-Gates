// =====================================================================
//  cpu_arm16.v
//  16-bit ARM-FLAVOURED CPU: full conditional execution (NZCV),
//  3-operand data processing, inline barrel shifter on operand 2,
//  S-bit flag writes, ARM carry convention (SUB sets C = no-borrow),
//  BL/BX subroutine linkage through r14. 32-bit Harvard instructions
//  on imem_*; 32-word data RAM. See docs/cpus.md for the encoding.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_cpu_arm16(
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
    reg [15:0] r [0:15];        // r14 = LR by convention
    reg [15:0] dmem [0:31];
    reg fN, fZ, fC, fV;            // NZCV

    // ---- field extraction ---------------------------------------------
    wire [3:0] cond  = imem_data[31:28];
    wire       sbit  = imem_data[27];
    wire [1:0] cls   = imem_data[26:25];
    wire [3:0] op4   = imem_data[24:21];
    wire [3:0] rd    = imem_data[20:17];
    wire [3:0] rn    = imem_data[16:13];
    wire [3:0] rm    = imem_data[12:9];
    wire [1:0] shtyp = imem_data[8:7];
    wire [4:0] shamt = imem_data[6:2];
    wire [7:0] imm8  = imem_data[12:5];
    wire [16:0] imm17 = imem_data[16:0];

    // =====================================================================
    //  CONDITION CHECK -- the ARM signature: gates EVERY instruction
    // =====================================================================
    reg cond_pass;
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

    wire is_dp   = cond_pass & (cls[1] == 1'b0);
    wire is_mem  = cond_pass & (cls == 2'b10);
    wire is_flow = cond_pass & (cls == 2'b11);
    wire is_test = (op4 >= 4'd12);               // CMP CMN TST TEQ
    wire wr_flag = is_dp & (sbit | is_test);

    wire [15:0] rnv = r[rn];
    wire [15:0] rmv = r[rm];

    // =====================================================================
    //  BARREL SHIFTER on operand 2 (operand-isolated: only live for
    //  register-form data processing, flagship gating style)
    // =====================================================================
    wire sh_en = is_dp & (cls == 2'b00);
    wire [15:0] sh_in = rmv & {16{sh_en}};
    wire [4:0]  sh_n  = shamt & {5{sh_en}};
    // rotate uses the amount modulo W; shifts saturate naturally
    reg [15:0] sh_out; reg sh_cout;
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

    // operand 2: shifted register (cls 00) or zero-extended imm8 (cls 01)
    wire [15:0] imm8w = {{8{1'b0}}, imm8};
    wire [15:0] op2 = (cls == 2'b00) ? sh_out : imm8w;

    // =====================================================================
    //  DATA-PROCESSING ALU (arith carry-chained, ARM C convention)
    // =====================================================================
    wire sel_arith = is_dp & ((op4 >= 4'd2 & op4 <= 4'd6) |
                              (op4 == 4'd12) | (op4 == 4'd13)); // SUB..SBC CMP CMN
    wire sel_logic = is_dp & ~sel_arith;

    wire [15:0] aa = rnv & {16{sel_arith}};
    wire [15:0] ab = op2 & {16{sel_arith}};
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
    wire [15:0] ar_y = adS[15:0];
    wire ar_c = adS[16];                 // ARM: C = NOT borrow on subtract
    wire ar_v = (adA[15] == adB[15]) & (ar_y[15] != adA[15]);

    wire [15:0] la = rnv & {16{sel_logic}};
    wire [15:0] lb = op2 & {16{sel_logic}};
    reg  [15:0] lg_y;
    always @(*) begin case (op4)
        4'd0, 4'd14: lg_y = la & lb;        // AND TST
        4'd1, 4'd15: lg_y = la ^ lb;        // EOR TEQ
        4'd7:        lg_y = la | lb;        // ORR
        4'd9:        lg_y = ~lb;            // MVN
        4'd10:       lg_y = la & ~lb;       // BIC
        default:     lg_y = lb;             // MOV (8, 11)
    endcase end

    wire [15:0] dp_y = sel_arith ? ar_y : lg_y;
    wire dp_wr = is_dp & ~is_test;

    // ---- flow + memory --------------------------------------------------
    wire is_b    = is_flow & (op4 == 4'd0);
    wire is_bl   = is_flow & (op4 == 4'd1);
    wire is_bx   = is_flow & (op4 == 4'd2);
    wire is_outi = is_flow & (op4 == 4'd3);
    wire is_hlt  = is_flow & (op4 == 4'd4);
    wire is_ldr  = is_mem & ~op4[0];
    wire is_str  = is_mem &  op4[0];

    wire [4:0] mem_a = rnv[4:0] + imm8[4:0];
    wire [7:0] btgt  = pc + imm17[7:0];         // relative, word units
    wire [7:0] pc1   = pc + 8'd1;

    assign imem_addr = pc;
    assign dbg_pc    = pc;
    assign dbg_data  = r[dbg_sel];

    always @(posedge clk) begin
        out_valid <= 1'b0;
        if (rst) begin
            pc <= 8'd0; halted <= 1'b0;
            fN <= 1'b0; fZ <= 1'b0; fC <= 1'b0; fV <= 1'b0;
            out_data <= {16{1'b0}};
        end else if (!halted) begin
            pc <= (is_b | is_bl) ? btgt
                : is_bx          ? rnv[7:0]
                : is_hlt         ? pc
                :                  pc1;
            if (dp_wr)  r[rd] <= dp_y;
            if (is_ldr) r[rd] <= dmem[mem_a];
            if (is_str) dmem[mem_a] <= r[rd];
            if (is_bl)  r[14] <= {{8{1'b0}}, pc1};
            if (is_outi) begin out_data <= rnv; out_valid <= 1'b1; end
            if (is_hlt)  halted <= 1'b1;
            if (wr_flag) begin
                fN <= dp_y[15];
                fZ <= (dp_y == {16{1'b0}});
                if (sel_arith) begin fC <= ar_c; fV <= ar_v; end
                else if (cls == 2'b00) fC <= sh_cout;   // logical: shifter carry
            end
        end
    end
endmodule


