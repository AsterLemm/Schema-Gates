// =====================================================================
//  cpu_riscv16.v
//  16-bit RV-LITE single-cycle CPU (RISC-V-flavoured load/store ISA).
//  16 registers (x0=0), Harvard: 32-bit instructions on imem_* ports,
//  16-word internal data RAM. ALU uses flagship operand isolation
//  (sel_* gated inputs). See docs/cpus.md for the full encoding.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module cpu_riscv16(
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
    reg [15:0] x [0:15];        // x0 reads as zero
    reg [15:0] dmem [0:15];

    wire [3:0]  op    = imem_data[31:28];
    wire [3:0]  rd    = imem_data[27:24];
    wire [3:0]  rs1   = imem_data[23:20];
    wire [3:0]  rs2   = imem_data[19:16];
    wire [15:0] imm16 = imem_data[15:0];
    wire [3:0]  funct = imem_data[3:0];          // ALU-R sub-operation

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

    wire [15:0] rs1v = (rs1 == 4'd0) ? {16{1'b0}} : x[rs1];
    wire [15:0] rs2v = (rs2 == 4'd0) ? {16{1'b0}} : x[rs2];

    // single-cycle core: the path selects ARE the gates
    wire gate_add   = sel_add;
    wire gate_logic = sel_logic;
    wire gate_shift = sel_shift;
    wire gate_cmp   = sel_cmp;

    wire [15:0] alu_b = is_alur ? rs2v : immv;

    // ---- ALU, operand-isolated per path (flagship technique) ---------
    // gate_X low -> that path's operands are forced to zero, so its
    // internal logic does not toggle while another path computes.
    wire [15:0] add_a = rs1v & {16{gate_add}};
    wire [15:0] add_b = alu_b & {16{gate_add}};
    wire           add_sub_en = (funct == 4'd1);   // R-type SUB
    wire [15:0] add_y = add_sub_en ? (add_a - add_b) : (add_a + add_b);
    
    wire [15:0] log_a = rs1v & {16{gate_logic}};
    wire [15:0] log_b = alu_b & {16{gate_logic}};
    wire [15:0] log_y = (lsel == 2'd0) ? (log_a & log_b)
                         : (lsel == 2'd1) ? (log_a | log_b)
                         :                  (log_a ^ log_b);
    
    wire [15:0] shf_a = rs1v & {16{gate_shift}};
    wire [3:0] shf_n = rs2v[3:0] & {4{gate_shift}};
    // SRA on its own signed wire: inside a ?: chain with unsigned
    // branches, >>> would silently degrade to a logical shift
    wire signed [15:0] shf_as  = $signed(shf_a);
    wire        [15:0] shf_sra = shf_as >>> shf_n;
    wire [15:0] shf_y = (funct == 4'd5) ? (shf_a <<  shf_n)
                         : (funct == 4'd6) ? (shf_a >>  shf_n)
                         :                  shf_sra;
    
    wire [15:0] cmp_a = rs1v & {16{gate_cmp}};
    wire [15:0] cmp_b = alu_b & {16{gate_cmp}};
    wire           cmp_lt = (funct == 4'd8)
                          ? ($signed(cmp_a) < $signed(cmp_b))
                          : (cmp_a < cmp_b);
    wire [15:0] cmp_y = {{15{1'b0}}, cmp_lt};
    
    // path merge: one-hot by construction (decoder-style front mux)
    wire [15:0] alu_y = (add_y & {16{gate_add}})
                         | (log_y & {16{gate_logic}})
                         | (shf_y & {16{gate_shift}})
                         | (cmp_y & {16{gate_cmp}});

    // ---- branch comparator (separately gated, flagship style) ---------
    wire [15:0] bcm_a = rs1v & {16{is_branch}};
    wire [15:0] bcm_b = rs2v & {16{is_branch}};
    wire beq  = (bcm_a == bcm_b);
    wire blt  = ($signed(bcm_a) < $signed(bcm_b));
    wire btaken = is_branch & ( (op == 4'h8) ?  beq
                              : (op == 4'h9) ? ~beq
                              : (op == 4'hA) ?  blt
                              :                ~blt );   // BGE

    wire [7:0] pc1     = pc + 8'd1;
    wire [7:0] pc_imm  = pc + imm16[7:0];           // word offset
    wire [7:0] jalr_t  = alu_y[7:0];                // rs1 + imm
    wire [7:0] next_pc = (btaken | is_jal) ? pc_imm
                       : is_jalr           ? jalr_t
                       : is_halt           ? pc
                       :                     pc1;

    wire [15:0] load_v = dmem[alu_y[3:0]];
    wire [15:0] pcret  = {{8{1'b0}}, pc1};
    wire [15:0] wb_val = is_lui          ? imm16
                          : is_load          ? load_v
                          : (is_jal|is_jalr) ? pcret
                          :                    alu_y;

    assign imem_addr = pc;
    assign dbg_pc    = pc;
    assign dbg_data  = (dbg_sel == 4'd0) ? {16{1'b0}} : x[dbg_sel];

    always @(posedge clk) begin
        out_valid <= 1'b0;
        if (rst) begin
            pc <= 8'd0; halted <= 1'b0; out_data <= {16{1'b0}};
        end else if (!halted) begin
            pc <= next_pc;
            if (reg_write && rd != 4'd0) x[rd] <= wb_val;
            if (is_store) dmem[alu_y[3:0]] <= rs2v;
            if (is_out) begin out_data <= rs1v; out_valid <= 1'b1; end
            if (is_halt) halted <= 1'b1;
        end
    end
endmodule


