// =====================================================================
//  cpu_stack32.v
//  32-bit ZERO-ADDRESS STACK CPU (Forth-style dual-stack machine).
//  TOS/NOS in registers + 16-deep spill RAM = single-cycle ops;
//  separate 8-deep return stack for CALL/RET. 16-bit Harvard
//  instructions on imem_*; 32-word data RAM. See docs/cpus.md.
//  MODULAR: decode / ALU(arith+logic) / dstack / rstack / dmem
//  submodules; the TOS/NOS/pointer FSM stays in the top.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- cpu_stack32_decode : fields + instruction class decode ---
module cpu_stack32_decode(
    input  wire [15:0] ir,
    output wire [3:0]  op,
    output wire [11:0] imm12,
    output wire [31:0] pushv,
    output wire        is_pushi,
    output wire        is_load,
    output wire        is_store,
    output wire        is_binop,
    output wire        is_dup,
    output wire        is_drop,
    output wire        is_swap,
    output wire        is_over,
    output wire        is_jmp,
    output wire        is_jz,
    output wire        is_call,
    output wire        is_misc,
    output wire        is_ret,
    output wire        is_out,
    output wire        is_hlt
);
    assign op    = ir[15:12];
    assign imm12 = ir[11:0];
    assign pushv = {{20{imm12[11]}}, imm12};   // PUSHI value

    assign is_pushi = (op == 4'h0);
    assign is_load = (op == 4'h1);
    assign is_store = (op == 4'h2);
    assign is_binop = (op >= 4'h3) && (op <= 4'h7);
    assign is_dup = (op == 4'h8);
    assign is_drop = (op == 4'h9);
    assign is_swap = (op == 4'hA);
    assign is_over = (op == 4'hB);
    assign is_jmp = (op == 4'hC);
    assign is_jz = (op == 4'hD);
    assign is_call = (op == 4'hE);
    assign is_misc = (op == 4'hF);
    assign is_ret = is_misc && (imm12[1:0] == 2'd0);
    assign is_out = is_misc && (imm12[1:0] == 2'd1);
    assign is_hlt = is_misc && (imm12[1:0] == 2'd2);
endmodule

// --- cpu_stack32_alu_arith : ADD / SUB path (leaf of cpu_stack32_alu) ---
module cpu_stack32_alu_arith(
    input  wire [31:0] al_a,
    input  wire [31:0] al_b,
    input  wire [3:0]  op,
    output wire [31:0] y
);
    assign y = (op == 4'h3) ? (al_a + al_b)
             :                (al_a - al_b);
endmodule

// --- cpu_stack32_alu_logic : AND / OR / XOR path (leaf of cpu_stack32_alu) ---
module cpu_stack32_alu_logic(
    input  wire [31:0] al_a,
    input  wire [31:0] al_b,
    input  wire [3:0]  op,
    output wire [31:0] y
);
    assign y = (op == 4'h5) ? (al_a & al_b)
             : (op == 4'h6) ? (al_a | al_b)
             :                (al_a ^ al_b);
endmodule

// --- cpu_stack32_alu : binop ALU on the two top cells (operand-isolated) ---
module cpu_stack32_alu(
    input  wire [31:0] nos,
    input  wire [31:0] tos,
    input  wire        is_binop,
    input  wire [3:0]  op,
    output wire [31:0] al_y
);
    wire [31:0] al_a = nos & {32{is_binop}};
    wire [31:0] al_b = tos & {32{is_binop}};
    wire [31:0] ar_y, lg_y;
    cpu_stack32_alu_arith u_arith(.al_a(al_a), .al_b(al_b), .op(op), .y(ar_y));
    cpu_stack32_alu_logic u_logic(.al_a(al_a), .al_b(al_b), .op(op), .y(lg_y));
    // op 3/4 -> arith path, 5/6/7 -> logic path (same one-hot select
    // chain as the old single mux; non-binop ops are operand-isolated)
    assign al_y = ((op == 4'h3) | (op == 4'h4)) ? ar_y : lg_y;
endmodule

// --- cpu_stack32_dstack : 16-deep data-stack spill RAM (cells BELOW nos) ---
module cpu_stack32_dstack(
    input  wire        clk,
    input  wire        we,
    input  wire [3:0]  waddr,
    input  wire [31:0] wdata,
    input  wire [3:0]  raddr,
    output wire [31:0] rdata
);
    reg [31:0] dstk [0:15];     // cells BELOW nos

    assign rdata = dstk[raddr];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) dstk[waddr] <= wdata;
    end
endmodule

// --- cpu_stack32_rstack : 8-deep return stack (the dual-stack signature) ---
module cpu_stack32_rstack(
    input  wire        clk,
    input  wire        we,
    input  wire [2:0]  waddr,
    input  wire [7:0]  wdata,
    input  wire [2:0]  raddr,
    output wire [7:0]  rdata
);
    reg [7:0] rstk [0:7];

    assign rdata = rstk[raddr];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) rstk[waddr] <= wdata;
    end
endmodule

// --- cpu_stack32_dmem : 32-word data RAM (sync write, async read) ---
module cpu_stack32_dmem(
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);
    reg [31:0] dmem [0:31];

    assign rdata = dmem[addr];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) dmem[addr] <= wdata;
    end
endmodule

module cpu_stack32(
    input  wire        clk,
    input  wire        rst,
    // Harvard instruction port (word addressed; supply ROM externally)
    output wire [7:0]  imem_addr,
    input  wire [15:0] imem_data,
    // OUT instruction port
    output reg  [31:0]  out_data,
    output reg         out_valid,
    // status / debug
    output reg         halted,
    output wire [31:0]  dbg_tos,
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
    reg [31:0] tos, nos;
    reg [4:0] dsp;                 // count of spilled cells
    reg [4:0] depth;               // total items (tos+nos+spill)

    // ---- return stack pointer (stack itself in u_rstack) --------------
    reg [3:0] rsp;

    // ---- decode ------------------------------------------------------
    wire [3:0]  op;
    wire [11:0] imm12;
    wire [31:0] pushv;
    wire is_pushi, is_load, is_store, is_binop, is_dup, is_drop;
    wire is_swap, is_over, is_jmp, is_jz, is_call, is_misc;
    wire is_ret, is_out, is_hlt;
    cpu_stack32_decode u_decode(
        .ir(imem_data),
        .op(op), .imm12(imm12), .pushv(pushv),
        .is_pushi(is_pushi), .is_load(is_load), .is_store(is_store),
        .is_binop(is_binop), .is_dup(is_dup), .is_drop(is_drop),
        .is_swap(is_swap), .is_over(is_over), .is_jmp(is_jmp),
        .is_jz(is_jz), .is_call(is_call), .is_misc(is_misc),
        .is_ret(is_ret), .is_out(is_out), .is_hlt(is_hlt)
    );

    // write gating: identical condition to the old monolithic block
    // (writes happened only in the `else if (!halted)` branch).
    wire wr_gate = ~rst & ~halted;

    // ---- ALU on the two top cells (operand-isolated) ------------------
    wire [31:0] al_y;
    cpu_stack32_alu u_alu(
        .nos(nos), .tos(tos), .is_binop(is_binop), .op(op),
        .al_y(al_y)
    );

    // ---- data-stack spill RAM -----------------------------------------
    // pushes (PUSHI/LOAD/DUP/OVER) spill nos at dstk[dsp]; the cell
    // under NOS reads back at dstk[dsp-1], exactly as before.
    wire [31:0] third;   // cell under NOS
    cpu_stack32_dstack u_dstack(
        .clk(clk),
        .we(wr_gate & (is_pushi | is_load | is_dup | is_over)),
        .waddr(dsp[3:0]), .wdata(nos),
        .raddr(dsp[3:0] - 4'd1), .rdata(third)
    );

    // ---- return stack --------------------------------------------------
    wire [7:0] rtop;   // return address under rsp
    cpu_stack32_rstack u_rstack(
        .clk(clk),
        .we(wr_gate & is_call),
        .waddr(rsp[2:0]), .wdata(pc + 8'd1),
        .raddr(rsp[2:0] - 3'd1), .rdata(rtop)
    );

    // ---- data RAM ------------------------------------------------------
    wire [31:0] dmem_rd;
    cpu_stack32_dmem u_dmem(
        .clk(clk),
        .we(wr_gate & is_store),
        .addr(imm12[4:0]), .wdata(tos),
        .rdata(dmem_rd)
    );

    wire tos_zero = (tos == {32{1'b0}});

    assign imem_addr = pc;
    assign dbg_pc    = pc;
    assign dbg_tos   = tos;
    assign dbg_depth = depth;

    // sequencing: identical to the monolithic core; the dstk / rstk /
    // dmem writes moved into their modules with the same conditions.
    always @(posedge clk) begin
        out_valid <= 1'b0;
        if (rst) begin
            pc <= 8'd0; halted <= 1'b0;
            dsp <= 5'd0; depth <= 5'd0; rsp <= 4'd0;
            tos <= {32{1'b0}}; nos <= {32{1'b0}};
            out_data <= {32{1'b0}};
        end else if (!halted) begin
            pc <= pc + 8'd1;            // flow ops override below
            case (op)
                // ---- pushes: spill nos, shift tos->nos, load new tos ----
                4'h0, 4'h1: begin        // PUSHI / LOAD
                    // (the dstk[dsp] <= nos spill lives in u_dstack)
                    if (depth >= 5'd2) dsp <= dsp + 5'd1;
                    nos <= tos;
                    tos <= is_load ? dmem_rd : pushv;
                    depth <= depth + 5'd1;
                end
                4'h8: begin              // DUP = push(tos)
                    // (the dstk[dsp] <= nos spill lives in u_dstack)
                    if (depth >= 5'd2) dsp <= dsp + 5'd1;
                    nos <= tos;
                    depth <= depth + 5'd1;
                end
                4'hB: begin              // OVER = push(nos)
                    // (the dstk[dsp] <= nos spill lives in u_dstack)
                    if (depth >= 5'd2) dsp <= dsp + 5'd1;
                    tos <= nos;
                    nos <= tos;
                    depth <= depth + 5'd1;
                end
                // ---- pops: refill nos from spill RAM --------------------
                4'h2, 4'h9: begin        // STORE / DROP (pop one)
                    // (the dmem[imm12[4:0]] <= tos write lives in u_dmem)
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
                    // (the rstk[rsp] <= pc+1 write lives in u_rstack)
                    rsp <= rsp + 4'd1;
                    pc  <= imm12[7:0];
                end
                4'hF: case (imm12[1:0])
                    2'd0: begin                          // RET
                        pc  <= rtop;
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


