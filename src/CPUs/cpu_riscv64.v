// =====================================================================
//  cpu_riscv64.v
//  64-bit RV-LITE single-cycle CPU (RISC-V-flavoured load/store ISA).
//  16 registers (x0=0), Harvard: 32-bit instructions on imem_* ports,
//  16-word internal data RAM. ALU uses flagship operand isolation
//  (sel_* gated inputs). See docs/cpus.md for the full encoding.
//  MODULAR: decode / regfile / ALU(+4 leaf paths) / bru / wbsel /
//  dmem submodules give a DigitalJS-style drillable hierarchy.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- cpu_riscv64_decode : fields, instruction classes, ALU path selects ---
module cpu_riscv64_decode(
    input  wire [31:0] ir,
    output wire [3:0]  op,
    output wire [3:0]  rd,
    output wire [3:0]  rs1,
    output wire [3:0]  rs2,
    output wire [15:0] imm16,
    output wire [3:0]  funct,
    output wire [63:0] immv,
    output wire        is_alur,
    output wire        is_addi,
    output wire        is_andi,
    output wire        is_ori,
    output wire        is_xori,
    output wire        is_lui,
    output wire        is_load,
    output wire        is_store,
    output wire        is_branch,
    output wire        is_jal,
    output wire        is_jalr,
    output wire        is_out,
    output wire        is_halt,
    output wire        sel_add,
    output wire        sel_logic,
    output wire        sel_shift,
    output wire        sel_cmp,
    output wire [1:0]  lsel,
    output wire        reg_write
);
    assign op = ir[31:28];
    assign rd = ir[27:24];
    assign rs1 = ir[23:20];
    assign rs2 = ir[19:16];
    assign imm16 = ir[15:0];
    assign funct = ir[3:0];          // ALU-R sub-operation

    assign immv = {{48{imm16[15]}}, imm16};   // sign-extended

    assign is_alur = (op == 4'h0);
    assign is_addi = (op == 4'h1);
    assign is_andi = (op == 4'h2);
    assign is_ori = (op == 4'h3);
    assign is_xori = (op == 4'h4);
    assign is_lui = (op == 4'h5);
    assign is_load = (op == 4'h6);
    assign is_store = (op == 4'h7);
    assign is_branch = (op[3:2] == 2'b10);   // 8..B
    assign is_jal = (op == 4'hC);
    assign is_jalr = (op == 4'hD);
    assign is_out = (op == 4'hE);
    assign is_halt = (op == 4'hF);

    // ALU path selects (decoder-style):
    //   add   : ADD/SUB, ADDI, address generation for LW/SW/JALR
    assign sel_add = (is_alur & ((funct == 4'd0) | (funct == 4'd1)))
                   | is_addi | is_load | is_store | is_jalr;
    assign sel_logic = (is_alur & (funct >= 4'd2) & (funct <= 4'd4))
                   | is_andi | is_ori | is_xori;
    assign sel_shift = is_alur & (funct >= 4'd5) & (funct <= 4'd7);
    assign sel_cmp = is_alur & ((funct == 4'd8) | (funct == 4'd9));

    // logic sub-select (shared between R-type and I-type)
    assign lsel = is_andi ? 2'd0 : is_ori ? 2'd1 : is_xori ? 2'd2
                    : (funct == 4'd2) ? 2'd0 : (funct == 4'd3) ? 2'd1 : 2'd2;

    assign reg_write = is_alur | is_addi | is_andi | is_ori | is_xori
                   | is_lui | is_load | is_jal | is_jalr;
endmodule

// --- cpu_riscv64_regfile : 16x64 register file, x0 reads as zero ---
module cpu_riscv64_regfile(
    input  wire        clk,
    input  wire        we,
    input  wire [3:0]  waddr,
    input  wire [63:0] wdata,
    input  wire [3:0]  raddr1,
    input  wire [3:0]  raddr2,
    output wire [63:0] rdata1,
    output wire [63:0] rdata2,
    input  wire [3:0]  dbg_sel,
    output wire [63:0] dbg_data
);
    reg [63:0] x [0:15];        // x0 reads as zero

    assign rdata1 = (raddr1 == 4'd0) ? {64{1'b0}} : x[raddr1];
    assign rdata2 = (raddr2 == 4'd0) ? {64{1'b0}} : x[raddr2];
    assign dbg_data = (dbg_sel == 4'd0) ? {64{1'b0}} : x[dbg_sel];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we && waddr != 4'd0) x[waddr] <= wdata;
    end
endmodule

// --- cpu_riscv64_alu_addsub : ADD / SUB path (leaf of cpu_riscv64_alu) ---
module cpu_riscv64_alu_addsub(
    input  wire [63:0] a,
    input  wire [63:0] b,
    input  wire        sub_en,
    output wire [63:0] y
);
    assign y = sub_en ? (a - b) : (a + b);
endmodule

// --- cpu_riscv64_alu_logic : AND / OR / XOR path (leaf of cpu_riscv64_alu) ---
module cpu_riscv64_alu_logic(
    input  wire [63:0] a,
    input  wire [63:0] b,
    input  wire [1:0]  lsel,
    output wire [63:0] y
);
    assign y = (lsel == 2'd0) ? (a & b)
             : (lsel == 2'd1) ? (a | b)
             :                  (a ^ b);
endmodule

// --- cpu_riscv64_alu_shift : SLL / SRL / SRA path (leaf of cpu_riscv64_alu) ---
module cpu_riscv64_alu_shift(
    input  wire [63:0] a,
    input  wire [5:0] n,
    input  wire [3:0]  funct,
    output wire [63:0] y
);
    // SRA on its own signed wire: inside a ?: chain with unsigned
    // branches, >>> would silently degrade to a logical shift
    wire signed [63:0] sra_a = $signed(a);
    wire        [63:0] sra_y = sra_a >>> n;
    assign y = (funct == 4'd5) ? (a <<  n)
             : (funct == 4'd6) ? (a >>  n)
             :                  sra_y;
endmodule

// --- cpu_riscv64_alu_cmp : SLT / SLTU path (leaf of cpu_riscv64_alu) ---
module cpu_riscv64_alu_cmp(
    input  wire [63:0] a,
    input  wire [63:0] b,
    input  wire [3:0]  funct,
    output wire [63:0] y
);
    wire lt = (funct == 4'd8)
            ? ($signed(a) < $signed(b))
            : (a < b);
    assign y = {{63{1'b0}}, lt};
endmodule

// --- cpu_riscv64_alu : operand-isolated 4-path ALU (flagship technique) ---
// gate_X low -> that path's operands are forced to zero, so its
// internal logic does not toggle while another path computes.
module cpu_riscv64_alu(
    input  wire [63:0] rs1v,
    input  wire [63:0] rs2v,
    input  wire [63:0] immv,
    input  wire        is_alur,
    input  wire [3:0]  funct,
    input  wire [1:0]  lsel,
    input  wire        gate_add,
    input  wire        gate_logic,
    input  wire        gate_shift,
    input  wire        gate_cmp,
    output wire [63:0] alu_y
);
    wire [63:0] alu_b = is_alur ? rs2v : immv;

    wire [63:0] add_a = rs1v & {64{gate_add}};
    wire [63:0] add_b = alu_b & {64{gate_add}};
    wire           add_sub_en = (funct == 4'd1);   // R-type SUB
    wire [63:0] add_y;
    cpu_riscv64_alu_addsub u_path_add(.a(add_a), .b(add_b), .sub_en(add_sub_en), .y(add_y));

    wire [63:0] log_a = rs1v & {64{gate_logic}};
    wire [63:0] log_b = alu_b & {64{gate_logic}};
    wire [63:0] log_y;
    cpu_riscv64_alu_logic u_path_log(.a(log_a), .b(log_b), .lsel(lsel), .y(log_y));

    wire [63:0] shf_a = rs1v & {64{gate_shift}};
    wire [5:0] shf_n = rs2v[5:0] & {6{gate_shift}};
    wire [63:0] shf_y;
    cpu_riscv64_alu_shift u_path_shf(.a(shf_a), .n(shf_n), .funct(funct), .y(shf_y));

    wire [63:0] cmp_a = rs1v & {64{gate_cmp}};
    wire [63:0] cmp_b = alu_b & {64{gate_cmp}};
    wire [63:0] cmp_y;
    cpu_riscv64_alu_cmp u_path_cmp(.a(cmp_a), .b(cmp_b), .funct(funct), .y(cmp_y));

    // path merge: one-hot by construction (decoder-style front mux)
    assign alu_y = (add_y & {64{gate_add}})
                 | (log_y & {64{gate_logic}})
                 | (shf_y & {64{gate_shift}})
                 | (cmp_y & {64{gate_cmp}});
endmodule

// --- cpu_riscv64_bru : branch resolve + next-PC select ---
module cpu_riscv64_bru(
    input  wire [7:0]  pc,
    input  wire [15:0] imm16,
    input  wire [3:0]  op,
    input  wire        is_branch,
    input  wire        is_jal,
    input  wire        is_jalr,
    input  wire        is_halt,
    input  wire [63:0] rs1v,
    input  wire [63:0] rs2v,
    input  wire [63:0] alu_y,
    output wire        btaken,
    output wire [7:0]  pc1,
    output wire [7:0]  next_pc
);
    // ---- branch comparator (separately gated, flagship style) ---------
    wire [63:0] bcm_a = rs1v & {64{is_branch}};
    wire [63:0] bcm_b = rs2v & {64{is_branch}};
    wire beq  = (bcm_a == bcm_b);
    wire blt  = ($signed(bcm_a) < $signed(bcm_b));
    assign btaken = is_branch & ( (op == 4'h8) ?  beq
                              : (op == 4'h9) ? ~beq
                              : (op == 4'hA) ?  blt
                              :                ~blt );   // BGE

    assign pc1 = pc + 8'd1;
    wire [7:0] pc_imm  = pc + imm16[7:0];           // word offset
    wire [7:0] jalr_t  = alu_y[7:0];                // rs1 + imm
    assign next_pc = (btaken | is_jal) ? pc_imm
                       : is_jalr           ? jalr_t
                       : is_halt           ? pc
                       :                     pc1;
endmodule

// --- cpu_riscv64_wbsel : write-back value select ---
module cpu_riscv64_wbsel(
    input  wire        is_lui,
    input  wire        is_load,
    input  wire        is_jal,
    input  wire        is_jalr,
    input  wire [15:0] imm16,
    input  wire [63:0] load_v,
    input  wire [7:0]  pc1,
    input  wire [63:0] alu_y,
    output wire [63:0] wb_val
);
    wire [63:0] pcret  = {{56{1'b0}}, pc1};
    assign wb_val = is_lui          ? {imm16, {48{1'b0}}}
                          : is_load          ? load_v
                          : (is_jal|is_jalr) ? pcret
                          :                    alu_y;
endmodule

// --- cpu_riscv64_dmem : 16-word data RAM (sync write, async read) ---
module cpu_riscv64_dmem(
    input  wire        clk,
    input  wire        we,
    input  wire [3:0]  addr,
    input  wire [63:0] wdata,
    output wire [63:0] rdata
);
    reg [63:0] dmem [0:15];

    assign rdata = dmem[addr];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) dmem[addr] <= wdata;
    end
endmodule

module cpu_riscv64(
    input  wire        clk,
    input  wire        rst,
    // Harvard instruction port (word addressed; supply ROM externally)
    output wire [7:0]  imem_addr,
    input  wire [31:0] imem_data,
    // OUT instruction port
    output reg  [63:0]  out_data,
    output reg         out_valid,
    // status / debug
    output reg         halted,
    input  wire [3:0]  dbg_sel,
    output wire [63:0]  dbg_data,
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

    // ---- decode ------------------------------------------------------
    wire [3:0]  op, rd, rs1, rs2, funct;
    wire [15:0] imm16;
    wire [63:0] immv;
    wire is_alur, is_addi, is_andi, is_ori, is_xori, is_lui;
    wire is_load, is_store, is_branch, is_jal, is_jalr, is_out, is_halt;
    wire sel_add, sel_logic, sel_shift, sel_cmp;
    wire [1:0] lsel;
    wire reg_write;
    cpu_riscv64_decode u_decode(
        .ir(imem_data),
        .op(op), .rd(rd), .rs1(rs1), .rs2(rs2),
        .imm16(imm16), .funct(funct), .immv(immv),
        .is_alur(is_alur), .is_addi(is_addi), .is_andi(is_andi),
        .is_ori(is_ori), .is_xori(is_xori), .is_lui(is_lui),
        .is_load(is_load), .is_store(is_store), .is_branch(is_branch),
        .is_jal(is_jal), .is_jalr(is_jalr), .is_out(is_out),
        .is_halt(is_halt),
        .sel_add(sel_add), .sel_logic(sel_logic),
        .sel_shift(sel_shift), .sel_cmp(sel_cmp),
        .lsel(lsel), .reg_write(reg_write)
    );

    // write gating: identical condition to the old monolithic block
    // (writes happened only in the `else if (!halted)` branch).
    wire wr_gate = ~rst & ~halted;

    // ---- register file ----------------------------------------------
    wire [63:0] rs1v, rs2v, wb_val;
    cpu_riscv64_regfile u_regfile(
        .clk(clk),
        .we(wr_gate & reg_write),
        .waddr(rd), .wdata(wb_val),
        .raddr1(rs1), .raddr2(rs2),
        .rdata1(rs1v), .rdata2(rs2v),
        .dbg_sel(dbg_sel), .dbg_data(dbg_data)
    );

    // single-cycle core: the path selects ARE the gates
    wire gate_add   = sel_add;
    wire gate_logic = sel_logic;
    wire gate_shift = sel_shift;
    wire gate_cmp   = sel_cmp;

    // ---- ALU (operand-isolated paths inside) ------------------------
    wire [63:0] alu_y;
    cpu_riscv64_alu u_alu(
        .rs1v(rs1v), .rs2v(rs2v), .immv(immv),
        .is_alur(is_alur), .funct(funct), .lsel(lsel),
        .gate_add(gate_add), .gate_logic(gate_logic),
        .gate_shift(gate_shift), .gate_cmp(gate_cmp),
        .alu_y(alu_y)
    );

    // ---- branch resolve + next PC -----------------------------------
    wire btaken;
    wire [7:0] pc1, next_pc;
    cpu_riscv64_bru u_bru(
        .pc(pc), .imm16(imm16), .op(op),
        .is_branch(is_branch), .is_jal(is_jal),
        .is_jalr(is_jalr), .is_halt(is_halt),
        .rs1v(rs1v), .rs2v(rs2v), .alu_y(alu_y),
        .btaken(btaken), .pc1(pc1), .next_pc(next_pc)
    );

    // ---- data RAM ----------------------------------------------------
    wire [63:0] load_v;
    cpu_riscv64_dmem u_dmem(
        .clk(clk),
        .we(wr_gate & is_store),
        .addr(alu_y[3:0]), .wdata(rs2v),
        .rdata(load_v)
    );

    // ---- write-back select ------------------------------------------
    cpu_riscv64_wbsel u_wbsel(
        .is_lui(is_lui), .is_load(is_load),
        .is_jal(is_jal), .is_jalr(is_jalr),
        .imm16(imm16), .load_v(load_v),
        .pc1(pc1), .alu_y(alu_y),
        .wb_val(wb_val)
    );

    assign imem_addr = pc;
    assign dbg_pc    = pc;

    // sequencing: identical to the monolithic core; the regfile and
    // dmem writes moved into their modules with the same conditions.
    always @(posedge clk) begin
        out_valid <= 1'b0;
        if (rst) begin
            pc <= 8'd0; halted <= 1'b0; out_data <= {64{1'b0}};
        end else if (!halted) begin
            pc <= next_pc;
            if (is_out) begin out_data <= rs1v; out_valid <= 1'b1; end
            if (is_halt) halted <= 1'b1;
        end
    end
endmodule


