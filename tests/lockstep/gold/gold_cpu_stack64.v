// =====================================================================
//  cpu_stack64.v
//  64-bit ZERO-ADDRESS STACK CPU (Forth-style dual-stack machine).
//  TOS/NOS in registers + 16-deep spill RAM = single-cycle ops;
//  separate 8-deep return stack for CALL/RET. 16-bit Harvard
//  instructions on imem_*; 32-word data RAM. See docs/cpus.md.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_cpu_stack64(
    input  wire        clk,
    input  wire        rst,
    // Harvard instruction port (word addressed; supply ROM externally)
    output wire [7:0]  imem_addr,
    input  wire [15:0] imem_data,
    // OUT instruction port
    output reg  [63:0]  out_data,
    output reg         out_valid,
    // status / debug
    output reg         halted,
    output wire [63:0]  dbg_tos,
    output wire [4:0]  dbg_depth,
    output wire [7:0]  dbg_pc
);
    // define clk                    input   255.230.80
    // define rst                    input   255.80.80
    // define imem_addr              output  38.15.153
    // define imem_data              input   126.199.90
    // define out_data               output  120.255.160
    // define out_valid              output  97.255.239
    // define halted                 output  255.120.120
    // define dbg_tos                output  178.54.0
    // define dbg_depth              output  178.54.0
    // define dbg_pc                 output  255.0.26

    reg [7:0] pc;

    // ---- data stack: TOS/NOS registers + spill RAM --------------------
    reg [63:0] tos, nos;
    reg [63:0] dstk [0:15];     // cells BELOW nos
    reg [4:0] dsp;                 // count of spilled cells
    reg [4:0] depth;               // total items (tos+nos+spill)

    // ---- return stack (separate, the dual-stack signature) ------------
    reg [7:0] rstk [0:7];
    reg [3:0] rsp;

    reg [63:0] dmem [0:31];

    wire [3:0]  op    = imem_data[15:12];
    wire [11:0] imm12 = imem_data[11:0];
    wire [63:0] pushv = {{52{imm12[11]}}, imm12};   // PUSHI value

    wire is_pushi = (op == 4'h0);
    wire is_load  = (op == 4'h1);
    wire is_store = (op == 4'h2);
    wire is_binop = (op >= 4'h3) && (op <= 4'h7);
    wire is_dup   = (op == 4'h8);
    wire is_drop  = (op == 4'h9);
    wire is_swap  = (op == 4'hA);
    wire is_over  = (op == 4'hB);
    wire is_jmp   = (op == 4'hC);
    wire is_jz    = (op == 4'hD);
    wire is_call  = (op == 4'hE);
    wire is_misc  = (op == 4'hF);
    wire is_ret   = is_misc && (imm12[1:0] == 2'd0);
    wire is_out   = is_misc && (imm12[1:0] == 2'd1);
    wire is_hlt   = is_misc && (imm12[1:0] == 2'd2);

    // ---- ALU on the two top cells (operand-isolated) ------------------
    wire [63:0] al_a = nos & {64{is_binop}};
    wire [63:0] al_b = tos & {64{is_binop}};
    wire [63:0] al_y = (op == 4'h3) ? (al_a + al_b)
                        : (op == 4'h4) ? (al_a - al_b)
                        : (op == 4'h5) ? (al_a & al_b)
                        : (op == 4'h6) ? (al_a | al_b)
                        :                (al_a ^ al_b);

    wire [63:0] third = dstk[dsp[3:0] - 4'd1];   // cell under NOS
    wire tos_zero = (tos == {64{1'b0}});

    assign imem_addr = pc;
    assign dbg_pc    = pc;
    assign dbg_tos   = tos;
    assign dbg_depth = depth;

    always @(posedge clk) begin
        out_valid <= 1'b0;
        if (rst) begin
            pc <= 8'd0; halted <= 1'b0;
            dsp <= 5'd0; depth <= 5'd0; rsp <= 4'd0;
            tos <= {64{1'b0}}; nos <= {64{1'b0}};
            out_data <= {64{1'b0}};
        end else if (!halted) begin
            pc <= pc + 8'd1;            // flow ops override below
            case (op)
                // ---- pushes: spill nos, shift tos->nos, load new tos ----
                4'h0, 4'h1: begin        // PUSHI / LOAD
                    dstk[dsp[3:0]] <= nos;
                    if (depth >= 5'd2) dsp <= dsp + 5'd1;
                    nos <= tos;
                    tos <= is_load ? dmem[imm12[4:0]] : pushv;
                    depth <= depth + 5'd1;
                end
                4'h8: begin              // DUP = push(tos)
                    dstk[dsp[3:0]] <= nos;
                    if (depth >= 5'd2) dsp <= dsp + 5'd1;
                    nos <= tos;
                    depth <= depth + 5'd1;
                end
                4'hB: begin              // OVER = push(nos)
                    dstk[dsp[3:0]] <= nos;
                    if (depth >= 5'd2) dsp <= dsp + 5'd1;
                    tos <= nos;
                    nos <= tos;
                    depth <= depth + 5'd1;
                end
                // ---- pops: refill nos from spill RAM --------------------
                4'h2, 4'h9: begin        // STORE / DROP (pop one)
                    if (is_store) dmem[imm12[4:0]] <= tos;
                    tos <= nos;
                    nos <= third;
                    if (dsp != 5'd0) dsp <= dsp - 5'd1;
                    if (depth != 5'd0) depth <= depth - 5'd1;
                end
                4'h3, 4'h4, 4'h5, 4'h6, 4'h7: begin // binop: pop 2 push 1
                    tos <= al_y;
                    nos <= third;
                    if (dsp != 5'd0) dsp <= dsp - 5'd1;
                    if (depth != 5'd0) depth <= depth - 5'd1;
                end
                4'hA: begin              // SWAP
                    tos <= nos; nos <= tos;
                end
                // ---- flow ----------------------------------------------
                4'hC: pc <= imm12[7:0];                  // JMP
                4'hD: begin                              // JZ (pops)
                    if (tos_zero) pc <= imm12[7:0];
                    tos <= nos;
                    nos <= third;
                    if (dsp != 5'd0) dsp <= dsp - 5'd1;
                    if (depth != 5'd0) depth <= depth - 5'd1;
                end
                4'hE: begin                              // CALL
                    rstk[rsp[2:0]] <= pc + 8'd1;
                    rsp <= rsp + 4'd1;
                    pc  <= imm12[7:0];
                end
                4'hF: case (imm12[1:0])
                    2'd0: begin                          // RET
                        pc  <= rstk[rsp[2:0] - 3'd1];
                        rsp <= rsp - 4'd1;
                    end
                    2'd1: begin                          // OUT (pops)
                        out_data <= tos; out_valid <= 1'b1;
                        tos <= nos;
                        nos <= third;
                        if (dsp != 5'd0) dsp <= dsp - 5'd1;
                        if (depth != 5'd0) depth <= depth - 5'd1;
                    end
                    2'd2: halted <= 1'b1;                // HALT
                    default: ;                           // NOP
                endcase
                default: ;
            endcase
        end
    end
endmodule


