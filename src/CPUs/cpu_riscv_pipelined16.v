// =====================================================================
//  cpu_riscv_pipelined16.v
//  16-bit RV-LITE 5-STAGE PIPELINED CPU (IF / ID / EX / MEM / WB).
//  Same ISA as cpu_riscv* (programs port over unchanged). Features:
//  EX forwarding from EX/MEM + MEM/WB, one-cycle load-use interlock,
//  branch/jump resolution in EX with a two-slot flush, in-order HALT
//  drain. ppln_* pins are PIPELINE SYNCHRONIZER strobes (flagship
//  operand isolation): gate_X = ppln_X & sel_X; drive high to run.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module cpu_riscv_pipelined16(
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
    reg [15:0] x [0:15];

    wire [3:0]  op    = ifid_ir[31:28];
    wire [3:0]  rd    = ifid_ir[27:24];
    wire [3:0]  rs1   = ifid_ir[23:20];
    wire [3:0]  rs2   = ifid_ir[19:16];
    wire [15:0] imm16 = ifid_ir[15:0];
    wire [3:0]  funct = ifid_ir[3:0];          // ALU-R sub-operation

    wire [15:0] immv = imm16;

    wire is_alur   = (op == 4'h0);
    wire is_addi   = (op == 4'h1);
    wire is_andi   = (op == 4'h2);
    wire is_ori    = (op == 4'h3);
    wire is_xori   = (op == 4'h4);
    wire is_lui    = (op == 4'h5);
    wire is_load   = (op == 4'h6);
    wire is_store  = (op == 4'h7);
    wire is_branch = (op[3:2] == 2'b10);   // 8..B
    wire is_jal    = (op == 4'hC);
    wire is_jalr   = (op == 4'hD);
    wire is_out    = (op == 4'hE);
    wire is_halt   = (op == 4'hF);

    // ALU path selects (decoder-style):
    //   add   : ADD/SUB, ADDI, address generation for LW/SW/JALR
    wire sel_add   = (is_alur & ((funct == 4'd0) | (funct == 4'd1)))
                   | is_addi | is_load | is_store | is_jalr;
    wire sel_logic = (is_alur & (funct >= 4'd2) & (funct <= 4'd4))
                   | is_andi | is_ori | is_xori;
    wire sel_shift = is_alur & (funct >= 4'd5) & (funct <= 4'd7);
    wire sel_cmp   = is_alur & ((funct == 4'd8) | (funct == 4'd9));

    // logic sub-select (shared between R-type and I-type)
    wire [1:0] lsel = is_andi ? 2'd0 : is_ori ? 2'd1 : is_xori ? 2'd2
                    : (funct == 4'd2) ? 2'd0 : (funct == 4'd3) ? 2'd1 : 2'd2;

    wire reg_write = is_alur | is_addi | is_andi | is_ori | is_xori
                   | is_lui | is_load | is_jal | is_jalr;

    // MEM/WB write-back (declared early: ID reads the file it writes)
    reg         memwb_v, memwb_rw;
    reg  [3:0]  memwb_rd;
    reg [15:0] memwb_val;

    // transparent regfile: WB value bypasses to ID in the same cycle
    wire [15:0] rf1 = (rs1 == 4'd0) ? {16{1'b0}}
                      : (memwb_v && memwb_rw && memwb_rd == rs1) ? memwb_val
                      : x[rs1];
    wire [15:0] rf2 = (rs2 == 4'd0) ? {16{1'b0}}
                      : (memwb_v && memwb_rw && memwb_rd == rs2) ? memwb_val
                      : x[rs2];

    // ID/EX pipeline register
    reg         idex_v;
    reg  [7:0]  idex_pc;
    reg [15:0] idex_rs1v, idex_rs2v, idex_imm;
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
    reg [15:0] exmem_val, exmem_sval;   // ALU/wb value, store data

    // forwarding unit: newest result wins (EX/MEM over MEM/WB)
    wire [15:0] fwd1 = (exmem_v && exmem_rw && exmem_rd != 4'd0
                        && exmem_rd == idex_rs1) ? exmem_val
                      : (memwb_v && memwb_rw && memwb_rd != 4'd0
                        && memwb_rd == idex_rs1) ? memwb_val
                      : idex_rs1v;
    wire [15:0] fwd2 = (exmem_v && exmem_rw && exmem_rd != 4'd0
                        && exmem_rd == idex_rs2) ? exmem_val
                      : (memwb_v && memwb_rw && memwb_rd != 4'd0
                        && memwb_rd == idex_rs2) ? memwb_val
                      : idex_rs2v;

    // pipeline synchronizer gating: external strobe AND internal select
    wire gate_add   = ppln_add   & idex_sadd  & idex_v;
    wire gate_logic = ppln_logic & idex_slog  & idex_v;
    wire gate_shift = ppln_shift & idex_sshf  & idex_v;
    wire gate_cmp   = ppln_cmp   & idex_scmp  & idex_v;

    wire [15:0] ex_b = idex_alur ? fwd2 : idex_imm;

    // ---- ALU, operand-isolated per path (flagship technique) ---------
    // gate_X low -> that path's operands are forced to zero, so its
    // internal logic does not toggle while another path computes.
    wire [15:0] add_a = fwd1 & {16{gate_add}};
    wire [15:0] add_b = ex_b & {16{gate_add}};
    wire           add_sub_en = (idex_funct == 4'd1);   // R-type SUB
    wire [15:0] add_y = add_sub_en ? (add_a - add_b) : (add_a + add_b);
    
    wire [15:0] log_a = fwd1 & {16{gate_logic}};
    wire [15:0] log_b = ex_b & {16{gate_logic}};
    wire [15:0] log_y = (idex_lsel == 2'd0) ? (log_a & log_b)
                         : (idex_lsel == 2'd1) ? (log_a | log_b)
                         :                  (log_a ^ log_b);
    
    wire [15:0] shf_a = fwd1 & {16{gate_shift}};
    wire [3:0] shf_n = fwd2[3:0] & {4{gate_shift}};
    // SRA on its own signed wire: inside a ?: chain with unsigned
    // branches, >>> would silently degrade to a logical shift
    wire signed [15:0] shf_as  = $signed(shf_a);
    wire        [15:0] shf_sra = shf_as >>> shf_n;
    wire [15:0] shf_y = (idex_funct == 4'd5) ? (shf_a <<  shf_n)
                         : (idex_funct == 4'd6) ? (shf_a >>  shf_n)
                         :                  shf_sra;
    
    wire [15:0] cmp_a = fwd1 & {16{gate_cmp}};
    wire [15:0] cmp_b = ex_b & {16{gate_cmp}};
    wire           cmp_lt = (idex_funct == 4'd8)
                          ? ($signed(cmp_a) < $signed(cmp_b))
                          : (cmp_a < cmp_b);
    wire [15:0] cmp_y = {{15{1'b0}}, cmp_lt};
    
    // path merge: one-hot by construction (decoder-style front mux)
    wire [15:0] alu_y = (add_y & {16{gate_add}})
                         | (log_y & {16{gate_logic}})
                         | (shf_y & {16{gate_shift}})
                         | (cmp_y & {16{gate_cmp}});

    // branch comparator -- gated like the flagship Branch_Unit
    wire gate_bcmp = idex_branch & idex_v;
    wire [15:0] bcm_a = fwd1 & {16{gate_bcmp}};
    wire [15:0] bcm_b = fwd2 & {16{gate_bcmp}};
    wire beq = (bcm_a == bcm_b);
    wire blt = ($signed(bcm_a) < $signed(bcm_b));
    wire btaken = gate_bcmp & ( (idex_op == 4'h8) ?  beq
                              : (idex_op == 4'h9) ? ~beq
                              : (idex_op == 4'hA) ?  blt
                              :                    ~blt );

    wire [7:0] ex_pc1   = idex_pc + 8'd1;
    wire [7:0] ex_pcimm = idex_pc + idex_imm16[7:0];
    assign redirect    = idex_v & (btaken | idex_jal | idex_jalr | idex_halt);
    assign redirect_pc = idex_halt ? idex_pc
                       : idex_jalr ? alu_y[7:0]
                       :             ex_pcimm;

    wire [15:0] ex_pcret = {{8{1'b0}}, ex_pc1};
    wire [15:0] ex_wbv = idex_lui              ? idex_imm16
                          : (idex_jal | idex_jalr) ? ex_pcret
                          : idex_outi              ? fwd1
                          :                          alu_y;

    // load-use interlock: the ID instruction may need a value the load
    // in EX has not produced yet -> hold IF/ID one cycle, bubble EX.
    // (conservative: any rd/rs match stalls; no per-class read masks)
    assign stall = idex_v & idex_load & ifid_v & (idex_rd != 4'd0)
                 & ((idex_rd == rs1) | (idex_rd == rs2));

    // =================================================================
    //  MEM  --  data RAM access, OUT port
    // =================================================================
    reg [15:0] dmem [0:15];
    wire [15:0] mem_rd = dmem[exmem_val[3:0]];

    // =================================================================
    //  WB  --  register write (transparent: see rf1/rf2 bypass in ID)
    // =================================================================
    assign dbg_data = (dbg_sel == 4'd0) ? {16{1'b0}} : x[dbg_sel];

    reg memwb_halt;

    always @(posedge clk) begin
        out_valid <= 1'b0;
        if (rst) begin
            pc <= 8'd0;
            ifid_v <= 1'b0; idex_v <= 1'b0; exmem_v <= 1'b0; memwb_v <= 1'b0;
            ifid_pc <= 8'd0; ifid_ir <= 32'd0;
            memwb_halt <= 1'b0; halted <= 1'b0;
            out_data <= {16{1'b0}};
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
            if (exmem_v & exmem_store) dmem[exmem_val[3:0]] <= exmem_sval;
            if (exmem_v & exmem_outi) begin
                out_data <= exmem_val; out_valid <= 1'b1;
            end
            memwb_v    <= exmem_v;
            memwb_rw   <= exmem_rw;
            memwb_rd   <= exmem_rd;
            memwb_val  <= exmem_load ? mem_rd : exmem_val;
            memwb_halt <= exmem_halt & exmem_v;
            // ---------------- WB ----------------
            if (memwb_v && memwb_rw && memwb_rd != 4'd0)
                x[memwb_rd] <= memwb_val;
            if (memwb_v && memwb_halt) halted <= 1'b1;   // in-order retire
        end
    end
endmodule


