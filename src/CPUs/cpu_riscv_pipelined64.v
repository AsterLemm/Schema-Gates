// =====================================================================
//  cpu_riscv_pipelined64.v
//  64-bit RV-LITE 5-STAGE PIPELINED CPU (IF / ID / EX / MEM / WB).
//  Same ISA as cpu_riscv* (programs port over unchanged). Features:
//  EX forwarding from EX/MEM + MEM/WB, one-cycle load-use interlock,
//  branch/jump resolution in EX with a two-slot flush, in-order HALT
//  drain. ppln_* pins are PIPELINE SYNCHRONIZER strobes (flagship
//  operand isolation): gate_X = ppln_X & sel_X; drive high to run.
//  MODULAR: decode / regfile / fwd / ALU(+4 leaf paths) / bcmp /
//  exctl / hazard / dmem submodules; pipeline registers stay in the
//  top so the sequencing is bit-identical to the monolithic core.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- cpu_riscv_pipelined64_decode : fields, instruction classes, ALU path selects ---
module cpu_riscv_pipelined64_decode(
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

// --- cpu_riscv_pipelined64_regfile : 16x64 register file, x0 reads as zero ---
// transparent: the WB value bypasses to the read ports in the
// same cycle (wb_v/wb_rw/wb_rd/wb_val), exactly as before.
module cpu_riscv_pipelined64_regfile(
    input  wire        clk,
    input  wire        we,
    input  wire [3:0]  waddr,
    input  wire [63:0] wdata,
    input  wire [3:0]  raddr1,
    input  wire [3:0]  raddr2,
    input  wire        wb_v,
    input  wire        wb_rw,
    input  wire [3:0]  wb_rd,
    input  wire [63:0] wb_val,
    output wire [63:0] rdata1,
    output wire [63:0] rdata2,
    input  wire [3:0]  dbg_sel,
    output wire [63:0] dbg_data
);
    reg [63:0] x [0:15];        // x0 reads as zero

    assign rdata1 = (raddr1 == 4'd0) ? {64{1'b0}}
                  : (wb_v && wb_rw && wb_rd == raddr1) ? wb_val
                  : x[raddr1];
    assign rdata2 = (raddr2 == 4'd0) ? {64{1'b0}}
                  : (wb_v && wb_rw && wb_rd == raddr2) ? wb_val
                  : x[raddr2];
    assign dbg_data = (dbg_sel == 4'd0) ? {64{1'b0}} : x[dbg_sel];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we && waddr != 4'd0) x[waddr] <= wdata;
    end
endmodule

// --- cpu_riscv_pipelined64_fwd : EX forwarding (EX/MEM and MEM/WB sources) ---
module cpu_riscv_pipelined64_fwd(
    input  wire [63:0] idex_rs1v,
    input  wire [63:0] idex_rs2v,
    input  wire [3:0]  idex_rs1,
    input  wire [3:0]  idex_rs2,
    input  wire        exmem_v,
    input  wire        exmem_rw,
    input  wire [3:0]  exmem_rd,
    input  wire [63:0] exmem_val,
    input  wire        memwb_v,
    input  wire        memwb_rw,
    input  wire [3:0]  memwb_rd,
    input  wire [63:0] memwb_val,
    output wire [63:0] fwd1,
    output wire [63:0] fwd2
);
    // forwarding unit: newest result wins (EX/MEM over MEM/WB)
    assign fwd1 = (exmem_v && exmem_rw && exmem_rd != 4'd0
                        && exmem_rd == idex_rs1) ? exmem_val
                      : (memwb_v && memwb_rw && memwb_rd != 4'd0
                        && memwb_rd == idex_rs1) ? memwb_val
                      : idex_rs1v;
    assign fwd2 = (exmem_v && exmem_rw && exmem_rd != 4'd0
                        && exmem_rd == idex_rs2) ? exmem_val
                      : (memwb_v && memwb_rw && memwb_rd != 4'd0
                        && memwb_rd == idex_rs2) ? memwb_val
                      : idex_rs2v;
endmodule

// --- cpu_riscv_pipelined64_alu_addsub : ADD / SUB path (leaf of cpu_riscv_pipelined64_alu) ---
module cpu_riscv_pipelined64_alu_addsub(
    input  wire [63:0] a,
    input  wire [63:0] b,
    input  wire        sub_en,
    output wire [63:0] y
);
    assign y = sub_en ? (a - b) : (a + b);
endmodule

// --- cpu_riscv_pipelined64_alu_logic : AND / OR / XOR path (leaf of cpu_riscv_pipelined64_alu) ---
module cpu_riscv_pipelined64_alu_logic(
    input  wire [63:0] a,
    input  wire [63:0] b,
    input  wire [1:0]  lsel,
    output wire [63:0] y
);
    assign y = (lsel == 2'd0) ? (a & b)
             : (lsel == 2'd1) ? (a | b)
             :                  (a ^ b);
endmodule

// --- cpu_riscv_pipelined64_alu_shift : SLL / SRL / SRA path (leaf of cpu_riscv_pipelined64_alu) ---
module cpu_riscv_pipelined64_alu_shift(
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

// --- cpu_riscv_pipelined64_alu_cmp : SLT / SLTU path (leaf of cpu_riscv_pipelined64_alu) ---
module cpu_riscv_pipelined64_alu_cmp(
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

// --- cpu_riscv_pipelined64_alu : operand-isolated 4-path ALU (flagship technique) ---
// gate_X low -> that path's operands are forced to zero, so its
// internal logic does not toggle while another path computes.
module cpu_riscv_pipelined64_alu(
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
    cpu_riscv_pipelined64_alu_addsub u_path_add(.a(add_a), .b(add_b), .sub_en(add_sub_en), .y(add_y));

    wire [63:0] log_a = rs1v & {64{gate_logic}};
    wire [63:0] log_b = alu_b & {64{gate_logic}};
    wire [63:0] log_y;
    cpu_riscv_pipelined64_alu_logic u_path_log(.a(log_a), .b(log_b), .lsel(lsel), .y(log_y));

    wire [63:0] shf_a = rs1v & {64{gate_shift}};
    wire [5:0] shf_n = rs2v[5:0] & {6{gate_shift}};
    wire [63:0] shf_y;
    cpu_riscv_pipelined64_alu_shift u_path_shf(.a(shf_a), .n(shf_n), .funct(funct), .y(shf_y));

    wire [63:0] cmp_a = rs1v & {64{gate_cmp}};
    wire [63:0] cmp_b = alu_b & {64{gate_cmp}};
    wire [63:0] cmp_y;
    cpu_riscv_pipelined64_alu_cmp u_path_cmp(.a(cmp_a), .b(cmp_b), .funct(funct), .y(cmp_y));

    // path merge: one-hot by construction (decoder-style front mux)
    assign alu_y = (add_y & {64{gate_add}})
                 | (log_y & {64{gate_logic}})
                 | (shf_y & {64{gate_shift}})
                 | (cmp_y & {64{gate_cmp}});
endmodule

// --- cpu_riscv_pipelined64_bcmp : gated branch comparator ---
module cpu_riscv_pipelined64_bcmp(
    input  wire [63:0] fwd1,
    input  wire [63:0] fwd2,
    input  wire [3:0]  idex_op,
    input  wire        idex_branch,
    input  wire        idex_v,
    output wire        btaken
);
    // branch comparator -- gated like the flagship Branch_Unit
    wire gate_bcmp = idex_branch & idex_v;
    wire [63:0] bcm_a = fwd1 & {64{gate_bcmp}};
    wire [63:0] bcm_b = fwd2 & {64{gate_bcmp}};
    wire beq = (bcm_a == bcm_b);
    wire blt = ($signed(bcm_a) < $signed(bcm_b));
    assign btaken = gate_bcmp & ( (idex_op == 4'h8) ?  beq
                              : (idex_op == 4'h9) ? ~beq
                              : (idex_op == 4'hA) ?  blt
                              :                    ~blt );
endmodule

// --- cpu_riscv_pipelined64_exctl : branch/jump redirect + WB value select (EX stage) ---
module cpu_riscv_pipelined64_exctl(
    input  wire        idex_v,
    input  wire [7:0]  idex_pc,
    input  wire [15:0] idex_imm16,
    input  wire        idex_halt,
    input  wire        idex_jal,
    input  wire        idex_jalr,
    input  wire        idex_lui,
    input  wire        idex_outi,
    input  wire [63:0] alu_y,
    input  wire        btaken,
    input  wire [63:0] fwd1,
    output wire        redirect,
    output wire [7:0]  redirect_pc,
    output wire [63:0] ex_wbv
);
    wire [7:0] ex_pc1   = idex_pc + 8'd1;
    wire [7:0] ex_pcimm = idex_pc + idex_imm16[7:0];
    assign redirect    = idex_v & (btaken | idex_jal | idex_jalr | idex_halt);
    assign redirect_pc = idex_halt ? idex_pc
                       : idex_jalr ? alu_y[7:0]
                       :             ex_pcimm;

    wire [63:0] ex_pcret = {{56{1'b0}}, ex_pc1};
    assign ex_wbv = idex_lui              ? {idex_imm16, {48{1'b0}}}
                          : (idex_jal | idex_jalr) ? ex_pcret
                          : idex_outi              ? fwd1
                          :                          alu_y;
endmodule

// --- cpu_riscv_pipelined64_hazard : load-use interlock detect ---
module cpu_riscv_pipelined64_hazard(
    input  wire        idex_v,
    input  wire        idex_load,
    input  wire [3:0]  idex_rd,
    input  wire        ifid_v,
    input  wire [3:0]  rs1,
    input  wire [3:0]  rs2,
    output wire        stall
);
    // load-use interlock: the ID instruction may need a value the load
    // in EX has not produced yet -> hold IF/ID one cycle, bubble EX.
    // (conservative: any rd/rs match stalls; no per-class read masks)
    assign stall = idex_v & idex_load & ifid_v & (idex_rd != 4'd0)
                 & ((idex_rd == rs1) | (idex_rd == rs2));
endmodule

// --- cpu_riscv_pipelined64_dmem : 16-word data RAM (sync write, async read) ---
module cpu_riscv_pipelined64_dmem(
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

module cpu_riscv_pipelined64(
    input  wire        clk,
    input  wire        rst,
    // Harvard instruction port (word addressed; supply ROM externally)
    output wire [7:0]  imem_addr,
    input  wire [31:0] imem_data,
    // pipeline synchronizer strobes -- drive high for normal run
    input  wire        ppln_add,
    input  wire        ppln_logic,
    input  wire        ppln_shift,
    input  wire        ppln_cmp,
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
    // define ppln_add               input   90.126.199
    // define ppln_logic             input   90.126.199
    // define ppln_shift             input   90.126.199
    // define ppln_cmp               input   90.126.199
    // define out_data               output  120.255.160
    // define out_valid              output  97.255.239
    // define halted                 output  255.120.120
    // define dbg_sel                input   200.120.255
    // define dbg_data               output  178.54.0
    // define dbg_pc                 output  255.0.26

    // =================================================================
    //  IF  --  instruction fetch
    // =================================================================
    reg  [7:0]  pc;
    wire        stall;        // load-use interlock (holds IF + ID)
    wire        redirect;     // taken branch / jump / halt (from EX)
    wire [7:0]  redirect_pc;

    assign imem_addr = pc;
    assign dbg_pc    = pc;

    reg  [7:0]  ifid_pc;
    reg  [31:0] ifid_ir;
    reg         ifid_v;

    // =================================================================
    //  ID  --  decode + register read
    // =================================================================
    wire [3:0]  op, rd, rs1, rs2, funct;
    wire [15:0] imm16;
    wire [63:0] immv;
    wire is_alur, is_addi, is_andi, is_ori, is_xori, is_lui;
    wire is_load, is_store, is_branch, is_jal, is_jalr, is_out, is_halt;
    wire sel_add, sel_logic, sel_shift, sel_cmp;
    wire [1:0] lsel;
    wire reg_write;
    cpu_riscv_pipelined64_decode u_decode(
        .ir(ifid_ir),
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

    // MEM/WB write-back (declared early: ID reads the file it writes)
    reg         memwb_v, memwb_rw;
    reg  [3:0]  memwb_rd;
    reg [63:0] memwb_val;

    // write gating: identical condition to the old monolithic block
    // (writes happened only in the `else if (!halted)` branch).
    wire wr_gate = ~rst & ~halted;

    // transparent regfile: WB value bypasses to ID in the same cycle
    wire [63:0] rf1, rf2;
    cpu_riscv_pipelined64_regfile u_regfile(
        .clk(clk),
        .we(wr_gate & memwb_v & memwb_rw),
        .waddr(memwb_rd), .wdata(memwb_val),
        .raddr1(rs1), .raddr2(rs2),
        .wb_v(memwb_v), .wb_rw(memwb_rw),
        .wb_rd(memwb_rd), .wb_val(memwb_val),
        .rdata1(rf1), .rdata2(rf2),
        .dbg_sel(dbg_sel), .dbg_data(dbg_data)
    );

    // ID/EX pipeline register
    reg         idex_v;
    reg  [7:0]  idex_pc;
    reg [63:0] idex_rs1v, idex_rs2v, idex_imm;
    reg  [3:0]  idex_rd, idex_rs1, idex_rs2, idex_op, idex_funct;
    reg  [1:0]  idex_lsel;
    reg         idex_alur, idex_lui, idex_load, idex_store, idex_branch;
    reg         idex_jal, idex_jalr, idex_outi, idex_halt, idex_rw;
    reg         idex_sadd, idex_slog, idex_sshf, idex_scmp;
    reg  [15:0] idex_imm16;

    // =================================================================
    //  EX  --  forwarding, operand-isolated ALU, branch resolve
    // =================================================================
    reg         exmem_v, exmem_rw, exmem_load, exmem_store;
    reg         exmem_outi, exmem_halt;
    reg  [3:0]  exmem_rd;
    reg [63:0] exmem_val, exmem_sval;   // ALU/wb value, store data

    wire [63:0] fwd1, fwd2;
    cpu_riscv_pipelined64_fwd u_fwd(
        .idex_rs1v(idex_rs1v), .idex_rs2v(idex_rs2v),
        .idex_rs1(idex_rs1), .idex_rs2(idex_rs2),
        .exmem_v(exmem_v), .exmem_rw(exmem_rw),
        .exmem_rd(exmem_rd), .exmem_val(exmem_val),
        .memwb_v(memwb_v), .memwb_rw(memwb_rw),
        .memwb_rd(memwb_rd), .memwb_val(memwb_val),
        .fwd1(fwd1), .fwd2(fwd2)
    );

    // pipeline synchronizer gating: external strobe AND internal select
    wire gate_add   = ppln_add   & idex_sadd  & idex_v;
    wire gate_logic = ppln_logic & idex_slog  & idex_v;
    wire gate_shift = ppln_shift & idex_sshf  & idex_v;
    wire gate_cmp   = ppln_cmp   & idex_scmp  & idex_v;

    // ---- ALU (operand-isolated paths inside) ------------------------
    wire [63:0] alu_y;
    cpu_riscv_pipelined64_alu u_alu(
        .rs1v(fwd1), .rs2v(fwd2), .immv(idex_imm),
        .is_alur(idex_alur), .funct(idex_funct), .lsel(idex_lsel),
        .gate_add(gate_add), .gate_logic(gate_logic),
        .gate_shift(gate_shift), .gate_cmp(gate_cmp),
        .alu_y(alu_y)
    );

    wire btaken;
    cpu_riscv_pipelined64_bcmp u_bcmp(
        .fwd1(fwd1), .fwd2(fwd2), .idex_op(idex_op),
        .idex_branch(idex_branch), .idex_v(idex_v),
        .btaken(btaken)
    );

    wire [63:0] ex_wbv;
    cpu_riscv_pipelined64_exctl u_exctl(
        .idex_v(idex_v), .idex_pc(idex_pc), .idex_imm16(idex_imm16),
        .idex_halt(idex_halt), .idex_jal(idex_jal),
        .idex_jalr(idex_jalr), .idex_lui(idex_lui),
        .idex_outi(idex_outi),
        .alu_y(alu_y), .btaken(btaken), .fwd1(fwd1),
        .redirect(redirect), .redirect_pc(redirect_pc),
        .ex_wbv(ex_wbv)
    );

    cpu_riscv_pipelined64_hazard u_hazard(
        .idex_v(idex_v), .idex_load(idex_load), .idex_rd(idex_rd),
        .ifid_v(ifid_v), .rs1(rs1), .rs2(rs2),
        .stall(stall)
    );

    // =================================================================
    //  MEM  --  data RAM access, OUT port
    // =================================================================
    wire [63:0] mem_rd;
    cpu_riscv_pipelined64_dmem u_dmem(
        .clk(clk),
        .we(wr_gate & exmem_v & exmem_store),
        .addr(exmem_val[3:0]), .wdata(exmem_sval),
        .rdata(mem_rd)
    );

    // =================================================================
    //  WB  --  register write (transparent: see rf1/rf2 bypass in ID)
    // =================================================================
    reg memwb_halt;

    always @(posedge clk) begin
        out_valid <= 1'b0;
        if (rst) begin
            pc <= 8'd0;
            ifid_v <= 1'b0; idex_v <= 1'b0; exmem_v <= 1'b0; memwb_v <= 1'b0;
            ifid_pc <= 8'd0; ifid_ir <= 32'd0;
            memwb_halt <= 1'b0; halted <= 1'b0;
            out_data <= {64{1'b0}};
        end else if (!halted) begin
            // ---------------- IF ----------------
            if (redirect) begin
                pc      <= redirect_pc;
                ifid_v  <= 1'b0;                  // flush slot 1
            end else if (!stall) begin
                pc      <= pc + 8'd1;
                ifid_pc <= pc;
                ifid_ir <= imem_data;
                ifid_v  <= 1'b1;
            end
            // ---------------- ID -> ID/EX ----------------
            if (redirect) begin
                idex_v <= 1'b0;                   // flush slot 2
            end else if (stall) begin
                idex_v <= 1'b0;                   // interlock bubble
            end else begin
                idex_v     <= ifid_v;
                idex_pc    <= ifid_pc;
                idex_rs1v  <= rf1;   idex_rs2v <= rf2;   idex_imm <= immv;
                idex_rd    <= rd;    idex_rs1  <= rs1;   idex_rs2 <= rs2;
                idex_op    <= op;    idex_funct <= funct; idex_lsel <= lsel;
                idex_imm16 <= imm16;
                idex_alur  <= is_alur;   idex_lui  <= is_lui;
                idex_load  <= is_load;   idex_store <= is_store;
                idex_branch<= is_branch; idex_jal  <= is_jal;
                idex_jalr  <= is_jalr;   idex_outi <= is_out;
                idex_halt  <= is_halt;   idex_rw   <= reg_write;
                idex_sadd  <= sel_add;   idex_slog <= sel_logic;
                idex_sshf  <= sel_shift; idex_scmp <= sel_cmp;
            end
            // ---------------- EX -> EX/MEM ----------------
            exmem_v    <= idex_v;
            exmem_rw   <= idex_rw   & idex_v;
            exmem_load <= idex_load & idex_v;
            exmem_store<= idex_store& idex_v;
            exmem_outi <= idex_outi & idex_v;
            exmem_halt <= idex_halt & idex_v;
            exmem_rd   <= idex_rd;
            exmem_val  <= ex_wbv;
            exmem_sval <= fwd2;
            // ---------------- MEM -> MEM/WB ----------------
            // (the dmem write itself lives in u_dmem, same condition)
            if (exmem_v & exmem_outi) begin
                out_data <= exmem_val; out_valid <= 1'b1;
            end
            memwb_v    <= exmem_v;
            memwb_rw   <= exmem_rw;
            memwb_rd   <= exmem_rd;
            memwb_val  <= exmem_load ? mem_rd : exmem_val;
            memwb_halt <= exmem_halt & exmem_v;
            // ---------------- WB ----------------
            // (the x[] write itself lives in u_regfile, same condition)
            if (memwb_v && memwb_halt) halted <= 1'b1;   // in-order retire
        end
    end
endmodule


