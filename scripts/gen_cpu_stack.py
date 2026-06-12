"""
gen_cpu_stack.py  ->  src/CPUs/cpu_stack{4,8,16,32,64}.v

ZERO-ADDRESS STACK CPU (Forth-style dual-stack machine).

The defining traits:
  * operands are implicit: binops pop two cells and push one result
  * TOS/NOS live in registers (single-cycle ALU) with a 16-deep spill
    RAM underneath; dsp counts spilled cells, depth counts all items
  * a SEPARATE 8-deep return stack serves CALL/RET (the dual-stack
    signature: data flow and control flow never share a stack)
  * 32-word data RAM for LOAD/STORE at imm12[4:0]

INSTRUCTION WORD  [15:12]=op  [11:0]=imm12
  op 0 PUSHI imm12 (sign-extended)   1 LOAD [imm5]   2 STORE [imm5]
     3 ADD 4 SUB 5 AND 6 OR 7 XOR    (binops: tos = nos OP tos)
     8 DUP 9 DROP A SWAP B OVER
     C JMP imm8   D JZ imm8 (pops)   E CALL imm8
     F misc (imm12[1:0]: 0 RET  1 OUT (pops)  2 HALT)

MODULAR EMISSION (DigitalJS-style hierarchy): <top>_decode / <top>_alu
(instantiating _alu_arith + _alu_logic leaf paths) / <top>_dstack
(spill RAM) / <top>_rstack (return stack) / <top>_dmem submodules; the
TOS/NOS/pointer FSM stays in the top. Every expression is carried over
verbatim from the monolithic emitter, so behaviour is identical.
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write
from _cpu_common import CPU_WIDTHS, define_line

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "CPUs")


def decode_module(n, w):
    if w >= 12:
        pim = f"{{{{{w-12}{{imm12[11]}}}}, imm12}}" if w > 12 else "imm12"
    else:
        pim = f"imm12[{w-1}:0]"
    return f"""\
// --- {n}_decode : fields + instruction class decode ---
module {n}_decode(
    input  wire [15:0] ir,
    output wire [3:0]  op,
    output wire [11:0] imm12,
    output wire [{w-1}:0] pushv,
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
    assign pushv = {pim};   // PUSHI value

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
endmodule"""


def alu_arith_module(n, w):
    return f"""\
// --- {n}_alu_arith : ADD / SUB path (leaf of {n}_alu) ---
module {n}_alu_arith(
    input  wire [{w-1}:0] al_a,
    input  wire [{w-1}:0] al_b,
    input  wire [3:0]  op,
    output wire [{w-1}:0] y
);
    assign y = (op == 4'h3) ? (al_a + al_b)
             :                (al_a - al_b);
endmodule"""


def alu_logic_module(n, w):
    return f"""\
// --- {n}_alu_logic : AND / OR / XOR path (leaf of {n}_alu) ---
module {n}_alu_logic(
    input  wire [{w-1}:0] al_a,
    input  wire [{w-1}:0] al_b,
    input  wire [3:0]  op,
    output wire [{w-1}:0] y
);
    assign y = (op == 4'h5) ? (al_a & al_b)
             : (op == 4'h6) ? (al_a | al_b)
             :                (al_a ^ al_b);
endmodule"""


def alu_module(n, w):
    return f"""\
// --- {n}_alu : binop ALU on the two top cells (operand-isolated) ---
module {n}_alu(
    input  wire [{w-1}:0] nos,
    input  wire [{w-1}:0] tos,
    input  wire        is_binop,
    input  wire [3:0]  op,
    output wire [{w-1}:0] al_y
);
    wire [{w-1}:0] al_a = nos & {{{w}{{is_binop}}}};
    wire [{w-1}:0] al_b = tos & {{{w}{{is_binop}}}};
    wire [{w-1}:0] ar_y, lg_y;
    {n}_alu_arith u_arith(.al_a(al_a), .al_b(al_b), .op(op), .y(ar_y));
    {n}_alu_logic u_logic(.al_a(al_a), .al_b(al_b), .op(op), .y(lg_y));
    // op 3/4 -> arith path, 5/6/7 -> logic path (same one-hot select
    // chain as the old single mux; non-binop ops are operand-isolated)
    assign al_y = ((op == 4'h3) | (op == 4'h4)) ? ar_y : lg_y;
endmodule"""


def dstack_module(n, w):
    return f"""\
// --- {n}_dstack : 16-deep data-stack spill RAM (cells BELOW nos) ---
module {n}_dstack(
    input  wire        clk,
    input  wire        we,
    input  wire [3:0]  waddr,
    input  wire [{w-1}:0] wdata,
    input  wire [3:0]  raddr,
    output wire [{w-1}:0] rdata
);
    reg [{w-1}:0] dstk [0:15];     // cells BELOW nos

    assign rdata = dstk[raddr];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) dstk[waddr] <= wdata;
    end
endmodule"""


def rstack_module(n):
    return f"""\
// --- {n}_rstack : 8-deep return stack (the dual-stack signature) ---
module {n}_rstack(
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
endmodule"""


def dmem_module(n, w):
    return f"""\
// --- {n}_dmem : 32-word data RAM (sync write, async read) ---
module {n}_dmem(
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  addr,
    input  wire [{w-1}:0] wdata,
    output wire [{w-1}:0] rdata
);
    reg [{w-1}:0] dmem [0:31];

    assign rdata = dmem[addr];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) dmem[addr] <= wdata;
    end
endmodule"""


def gen(w):
    name = f"cpu_stack{w}"
    hdr = banner(f"{name}.v", [
        f"{w}-bit ZERO-ADDRESS STACK CPU (Forth-style dual-stack machine).",
        "TOS/NOS in registers + 16-deep spill RAM = single-cycle ops;",
        "separate 8-deep return stack for CALL/RET. 16-bit Harvard",
        "instructions on imem_*; 32-word data RAM. See docs/cpus.md.",
        "MODULAR: decode / ALU(arith+logic) / dstack / rstack / dmem",
        "submodules; the TOS/NOS/pointer FSM stays in the top.",
    ])

    ports = f"""module {name}(
    input  wire        clk,
    input  wire        rst,
    // Harvard instruction port (word addressed; supply ROM externally)
    output wire [7:0]  imem_addr,
    input  wire [15:0] imem_data,
    // OUT instruction port
    output reg  [{w-1}:0]  out_data,
    output reg         out_valid,
    // status / debug
    output reg         halted,
    output wire [{w-1}:0]  dbg_tos,
    output wire [4:0]  dbg_depth,
    output wire [7:0]  dbg_pc
);
"""
    defs = define_line([
        ("clk", "input", "clk"), ("rst", "input", "rst"),
        ("imem_addr", "output", "imem_addr"), ("imem_data", "input", "imem_data"),
        ("out_data", "output", "out_data"), ("out_valid", "output", "out_valid"),
        ("halted", "output", "halted"),
        ("dbg_tos", "output", "dbg_acc"), ("dbg_depth", "output", "dbg_acc"),
        ("dbg_pc", "output", "dbg_pc"),
    ])

    mods = [decode_module(name, w),
            alu_arith_module(name, w), alu_logic_module(name, w),
            alu_module(name, w),
            dstack_module(name, w), rstack_module(name), dmem_module(name, w)]

    B = []
    B.append("    reg [7:0] pc;")
    B.append("")
    B.append("    // ---- data stack: TOS/NOS registers + spill RAM --------------------")
    B.append(f"    reg [{w-1}:0] tos, nos;")
    B.append("    reg [4:0] dsp;                 // count of spilled cells")
    B.append("    reg [4:0] depth;               // total items (tos+nos+spill)")
    B.append("")
    B.append("    // ---- return stack pointer (stack itself in u_rstack) --------------")
    B.append("    reg [3:0] rsp;")
    B.append("")
    B.append("    // ---- decode ------------------------------------------------------")
    B.append("    wire [3:0]  op;")
    B.append("    wire [11:0] imm12;")
    B.append(f"    wire [{w-1}:0] pushv;")
    B.append("    wire is_pushi, is_load, is_store, is_binop, is_dup, is_drop;")
    B.append("    wire is_swap, is_over, is_jmp, is_jz, is_call, is_misc;")
    B.append("    wire is_ret, is_out, is_hlt;")
    B.append(f"    {name}_decode u_decode(")
    B.append("        .ir(imem_data),")
    B.append("        .op(op), .imm12(imm12), .pushv(pushv),")
    B.append("        .is_pushi(is_pushi), .is_load(is_load), .is_store(is_store),")
    B.append("        .is_binop(is_binop), .is_dup(is_dup), .is_drop(is_drop),")
    B.append("        .is_swap(is_swap), .is_over(is_over), .is_jmp(is_jmp),")
    B.append("        .is_jz(is_jz), .is_call(is_call), .is_misc(is_misc),")
    B.append("        .is_ret(is_ret), .is_out(is_out), .is_hlt(is_hlt)")
    B.append("    );")
    B.append("")
    B.append("    // write gating: identical condition to the old monolithic block")
    B.append("    // (writes happened only in the `else if (!halted)` branch).")
    B.append("    wire wr_gate = ~rst & ~halted;")
    B.append("")
    B.append("    // ---- ALU on the two top cells (operand-isolated) ------------------")
    B.append(f"    wire [{w-1}:0] al_y;")
    B.append(f"    {name}_alu u_alu(")
    B.append("        .nos(nos), .tos(tos), .is_binop(is_binop), .op(op),")
    B.append("        .al_y(al_y)")
    B.append("    );")
    B.append("")
    B.append("    // ---- data-stack spill RAM -----------------------------------------")
    B.append("    // pushes (PUSHI/LOAD/DUP/OVER) spill nos at dstk[dsp]; the cell")
    B.append("    // under NOS reads back at dstk[dsp-1], exactly as before.")
    B.append(f"    wire [{w-1}:0] third;   // cell under NOS")
    B.append(f"    {name}_dstack u_dstack(")
    B.append("        .clk(clk),")
    B.append("        .we(wr_gate & (is_pushi | is_load | is_dup | is_over)),")
    B.append("        .waddr(dsp[3:0]), .wdata(nos),")
    B.append("        .raddr(dsp[3:0] - 4'd1), .rdata(third)")
    B.append("    );")
    B.append("")
    B.append("    // ---- return stack --------------------------------------------------")
    B.append("    wire [7:0] rtop;   // return address under rsp")
    B.append(f"    {name}_rstack u_rstack(")
    B.append("        .clk(clk),")
    B.append("        .we(wr_gate & is_call),")
    B.append("        .waddr(rsp[2:0]), .wdata(pc + 8'd1),")
    B.append("        .raddr(rsp[2:0] - 3'd1), .rdata(rtop)")
    B.append("    );")
    B.append("")
    B.append("    // ---- data RAM ------------------------------------------------------")
    B.append(f"    wire [{w-1}:0] dmem_rd;")
    B.append(f"    {name}_dmem u_dmem(")
    B.append("        .clk(clk),")
    B.append("        .we(wr_gate & is_store),")
    B.append("        .addr(imm12[4:0]), .wdata(tos),")
    B.append("        .rdata(dmem_rd)")
    B.append("    );")
    B.append("")
    B.append("    wire tos_zero = (tos == {%d{1'b0}});" % w)
    B.append("")
    B.append("    assign imem_addr = pc;")
    B.append("    assign dbg_pc    = pc;")
    B.append("    assign dbg_tos   = tos;")
    B.append("    assign dbg_depth = depth;")
    B.append("")
    B.append("    // sequencing: identical to the monolithic core; the dstk / rstk /")
    B.append("    // dmem writes moved into their modules with the same conditions.")
    B.append("    always @(posedge clk) begin")
    B.append("        out_valid <= 1'b0;")
    B.append("        if (rst) begin")
    B.append("            pc <= 8'd0; halted <= 1'b0;")
    B.append("            dsp <= 5'd0; depth <= 5'd0; rsp <= 4'd0;")
    B.append(f"            tos <= {{{w}{{1'b0}}}}; nos <= {{{w}{{1'b0}}}};")
    B.append(f"            out_data <= {{{w}{{1'b0}}}};")
    B.append("        end else if (!halted) begin")
    B.append("            pc <= pc + 8'd1;            // flow ops override below")
    B.append("            case (op)")
    B.append("                // ---- pushes: spill nos, shift tos->nos, load new tos ----")
    B.append("                4'h0, 4'h1: begin        // PUSHI / LOAD")
    B.append("                    // (the dstk[dsp] <= nos spill lives in u_dstack)")
    B.append("                    if (depth >= 5'd2) dsp <= dsp + 5'd1;")
    B.append("                    nos <= tos;")
    B.append("                    tos <= is_load ? dmem_rd : pushv;")
    B.append("                    depth <= depth + 5'd1;")
    B.append("                end")
    B.append("                4'h8: begin              // DUP = push(tos)")
    B.append("                    // (the dstk[dsp] <= nos spill lives in u_dstack)")
    B.append("                    if (depth >= 5'd2) dsp <= dsp + 5'd1;")
    B.append("                    nos <= tos;")
    B.append("                    depth <= depth + 5'd1;")
    B.append("                end")
    B.append("                4'hB: begin              // OVER = push(nos)")
    B.append("                    // (the dstk[dsp] <= nos spill lives in u_dstack)")
    B.append("                    if (depth >= 5'd2) dsp <= dsp + 5'd1;")
    B.append("                    tos <= nos;")
    B.append("                    nos <= tos;")
    B.append("                    depth <= depth + 5'd1;")
    B.append("                end")
    B.append("                // ---- pops: refill nos from spill RAM --------------------")
    B.append("                4'h2, 4'h9: begin        // STORE / DROP (pop one)")
    B.append("                    // (the dmem[imm12[4:0]] <= tos write lives in u_dmem)")
    B.append("                    tos <= nos;")
    B.append("                    nos <= third;")
    B.append("                    if (dsp != 5'd0) dsp <= dsp - 5'd1;")
    B.append("                    if (depth != 5'd0) depth <= depth - 5'd1;")
    B.append("                end")
    B.append("                4'h3, 4'h4, 4'h5, 4'h6, 4'h7: begin // binop: pop 2 push 1")
    B.append("                    tos <= al_y;")
    B.append("                    nos <= third;")
    B.append("                    if (dsp != 5'd0) dsp <= dsp - 5'd1;")
    B.append("                    if (depth != 5'd0) depth <= depth - 5'd1;")
    B.append("                end")
    B.append("                4'hA: begin              // SWAP")
    B.append("                    tos <= nos; nos <= tos;")
    B.append("                end")
    B.append("                // ---- flow ----------------------------------------------")
    B.append("                4'hC: pc <= imm12[7:0];                  // JMP")
    B.append("                4'hD: begin                              // JZ (pops)")
    B.append("                    if (tos_zero) pc <= imm12[7:0];")
    B.append("                    tos <= nos;")
    B.append("                    nos <= third;")
    B.append("                    if (dsp != 5'd0) dsp <= dsp - 5'd1;")
    B.append("                    if (depth != 5'd0) depth <= depth - 5'd1;")
    B.append("                end")
    B.append("                4'hE: begin                              // CALL")
    B.append("                    // (the rstk[rsp] <= pc+1 write lives in u_rstack)")
    B.append("                    rsp <= rsp + 4'd1;")
    B.append("                    pc  <= imm12[7:0];")
    B.append("                end")
    B.append("                4'hF: case (imm12[1:0])")
    B.append("                    2'd0: begin                          // RET")
    B.append("                        pc  <= rtop;")
    B.append("                        rsp <= rsp - 4'd1;")
    B.append("                    end")
    B.append("                    2'd1: begin                          // OUT (pops)")
    B.append("                        out_data <= tos; out_valid <= 1'b1;")
    B.append("                        tos <= nos;")
    B.append("                        nos <= third;")
    B.append("                        if (dsp != 5'd0) dsp <= dsp - 5'd1;")
    B.append("                        if (depth != 5'd0) depth <= depth - 5'd1;")
    B.append("                    end")
    B.append("                    2'd2: halted <= 1'b1;                // HALT")
    B.append("                    default: ;                           // NOP")
    B.append("                endcase")
    B.append("                default: ;")
    B.append("            endcase")
    B.append("        end")
    B.append("    end")
    B.append("endmodule")

    text = (hdr + "\n" + "\n\n".join(mods) + "\n\n"
            + ports + defs + "\n" + "\n".join(B) + "\n")
    write(os.path.join(OUT, name + ".v"), text)


for w in CPU_WIDTHS:
    gen(w)
print("CPUs: zero-address stack family generated (modular)")
