// =====================================================================
//  cpu_vonneumann8.v
//  8-bit VON NEUMANN accumulator CPU (multicycle, unified memory).
//  One 16x8 memory holds code AND data behind a single port,
//  so the FSM serializes fetch and execute (the classic bottleneck).
//  ISA: NOP LDA STA ADD SUB AND OR XOR LDI JMP JZ JC SHL SHR OUT HLT.
//  Load program via prog_* while run=0, then raise run (PC starts 0).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_cpu_vonneumann8(
    input  wire        clk,
    input  wire        rst,
    input  wire        run,
    // unified-memory load port (active while run=0)
    input  wire        prog_we,
    input  wire [3:0]  prog_addr,
    input  wire [7:0]  prog_data,
    // OUT instruction port
    output reg  [7:0]  out_data,
    output reg         out_valid,
    // status / debug
    output wire        halted,
    output wire [7:0]  dbg_acc,
    output wire [3:0]  dbg_pc
);
    // define clk                    input   255.230.80
    // define rst                    input   255.80.80
    // define run                    input   255.180.80
    // define prog_we                input   200.120.255
    // define prog_addr              input   160.120.255
    // define prog_data              input   120.120.255
    // define out_data               output  120.255.160
    // define out_valid              output  97.255.239
    // define halted                 output  255.120.120
    // define dbg_acc                output  178.54.0
    // define dbg_pc                 output  255.0.26

    // ------------------------------------------------------------------
    // UNIFIED MEMORY -- the von Neumann signature. Code and data share
    // this single array and its single read path; the FSM below decides
    // whether the current access is an instruction fetch or a data access.
    // ------------------------------------------------------------------
    reg [7:0] mem [0:15];

    localparam ST_FETCH  = 2'd0;
    localparam ST_EXEC   = 2'd1;
    localparam ST_HALT   = 2'd2;
    reg [1:0] state;

    reg [3:0] pc;
    reg [7:0] acc;
    reg [3:0] opcode;
    reg carry;

    wire zero = (acc == {8{1'b0}});

    // single memory read path, time-multiplexed by the FSM:
    //   ST_FETCH/ST_FETCH2 -> mem[pc] (instruction stream)
    //   ST_EXEC            -> mem[operand] (data, for LDA/ADD/...)
    // operand is registered with the opcode at the end of ST_FETCH
    reg  [3:0] operand;
    wire [3:0] cur_opcode  = opcode;
    wire [3:0] cur_operand = operand;
    wire [3:0] mem_raddr = (state == ST_EXEC) ? cur_operand : pc;
    wire [7:0] mem_rdata = mem[mem_raddr];

    // ---- ALU (operand-isolated, flagship style) ----------------------
    // Each path's inputs are ANDed with its select so unused paths hold 0.
    wire is_add = (opcode == 4'h3);
    wire is_sub = (opcode == 4'h4);
    wire sel_arith = is_add | is_sub;
    wire sel_logic = (opcode == 4'h5) | (opcode == 4'h6) | (opcode == 4'h7);
    wire sel_shift = (opcode == 4'hC) | (opcode == 4'hD);

    wire [7:0] ar_a = acc       & {8{sel_arith}};
    wire [7:0] ar_b = mem_rdata & {8{sel_arith}};
    wire [8:0]   ar_sum = is_sub ? ({1'b0, ar_a} - {1'b0, ar_b})
                                   : ({1'b0, ar_a} + {1'b0, ar_b});

    wire [7:0] lg_a = acc       & {8{sel_logic}};
    wire [7:0] lg_b = mem_rdata & {8{sel_logic}};
    wire [7:0] lg_y = (opcode == 4'h5) ? (lg_a & lg_b)
                        : (opcode == 4'h6) ? (lg_a | lg_b)
                        :                    (lg_a ^ lg_b);

    wire [7:0] sh_a = acc & {8{sel_shift}};
    wire [7:0] sh_y = (opcode == 4'hC) ? {sh_a[6:0], 1'b0}
                        :                    {1'b0, sh_a[7:1]};
    wire sh_c = (opcode == 4'hC) ? sh_a[7] : sh_a[0];

    assign halted  = (state == ST_HALT);
    assign dbg_acc = acc;
    assign dbg_pc  = pc;

    always @(posedge clk) begin
        out_valid <= 1'b0;
        if (rst) begin
            state <= ST_FETCH; pc <= 4'd0; acc <= {8{1'b0}};
            carry <= 1'b0; opcode <= 4'h0;
            operand <= 4'h0;
            out_data <= {8{1'b0}};
        end else if (!run) begin
            // program-load mode: the SAME unified memory is written here
            if (prog_we) mem[prog_addr] <= prog_data;
            state <= ST_FETCH; pc <= 4'd0;
        end else begin
            case (state)
                ST_FETCH: begin
                    opcode  <= mem_rdata[7:4];
                    operand <= mem_rdata[3:0];
                    pc      <= pc + 4'd1;
                    state   <= ST_EXEC;
                end
                ST_EXEC: begin
                    state <= ST_FETCH;
                    case (cur_opcode)
                        4'h0: ;                                   // NOP
                        4'h1: acc <= mem_rdata;                   // LDA
                        4'h2: mem[mem_raddr] <= acc;              // STA
                        4'h3: begin acc <= ar_sum[7:0]; carry <= ar_sum[8]; end // ADD
                        4'h4: begin acc <= ar_sum[7:0]; carry <= ar_sum[8]; end // SUB (carry = borrow)
                        4'h5, 4'h6, 4'h7: acc <= lg_y;            // AND OR XOR
                        4'h8: acc <= {{4{1'b0}}, cur_operand}; // LDI
                        4'h9: pc <= cur_operand;                       // JMP
                        4'hA: if (zero)  pc <= cur_operand;            // JZ
                        4'hB: if (carry) pc <= cur_operand;            // JC
                        4'hC, 4'hD: begin acc <= sh_y; carry <= sh_c; end // SHL SHR
                        4'hE: begin out_data <= acc; out_valid <= 1'b1; end // OUT
                        4'hF: state <= ST_HALT;                   // HLT
                        default: ;
                    endcase
                end
                ST_HALT: state <= ST_HALT;
                default: state <= ST_FETCH;
            endcase
        end
    end
endmodule


