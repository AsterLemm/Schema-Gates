"""
gen_cpu_stack.py  ->  src/CPUs/cpu_stack{4,8,16,32,64}.v

ZERO-ADDRESS STACK MACHINE (Forth / Burroughs lineage).
Single-cycle Harvard core, 16-bit instructions, data width W.

The defining stack-machine traits:
  * NO register operands: every ALU op implicitly uses the top two stack
    cells  (tos = nos OP tos, both popped, result pushed)
  * the classic TOS/NOS register optimisation: the two top cells live in
    registers; deeper cells spill into a 16-entry stack RAM, so every
    instruction completes in one cycle
  * a SEPARATE 8-deep RETURN STACK for CALL/RET (no pointer aliasing)

INSTRUCTION WORD  [15:12]=op  [11:0]=imm12  (sign-extended where used)
  op 0  PUSHI imm        push sign-extended imm12
  op 1  LOAD  imm        push dmem[imm[4:0]]      (32-word data RAM)
  op 2  STORE imm        dmem[imm[4:0]] = pop
  op 3  ADD   4 SUB   5 AND   6 OR   7 XOR        (nos OP tos)
  op 8  DUP   9 DROP  A SWAP  B OVER
  op C  JMP  imm         pc = imm[7:0]
  op D  JZ   imm         v = pop; if (v==0) pc = imm[7:0]
  op E  CALL imm         rstack.push(pc+1); pc = imm[7:0]
  op F  misc imm[1:0]:   0 RET   1 OUT (pop -> out port)   2 HALT   3 NOP
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write
from _cpu_common import CPU_WIDTHS, define_line

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "CPUs")


def gen(w):
    name = f"cpu_stack{w}"
    hdr = banner(f"{name}.v", [
        f"{w}-bit ZERO-ADDRESS STACK CPU (Forth-style dual-stack machine).",
        "TOS/NOS in registers + 16-deep spill RAM = single-cycle ops;",
        "separate 8-deep return stack for CALL/RET. 16-bit Harvard",
        "instructions on imem_*; 32-word data RAM. See docs/cpus.md.",
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
        ("dbg_tos", "output", "dbg_acc"), ("dbg_depth", "output", "dbg_data"),
        ("dbg_pc", "output", "dbg_pc"),
    ])

    if w >= 12:
        pim = f"{{{{{w-12}{{imm12[11]}}}}, imm12}}" if w > 12 else "imm12"
    else:
        pim = f"imm12[{w-1}:0]"

    B = []
    B.append("    reg [7:0] pc;")
    B.append("")
    B.append("    // ---- data stack: TOS/NOS registers + spill RAM --------------------")
    B.append(f"    reg [{w-1}:0] tos, nos;")
    B.append(f"    reg [{w-1}:0] dstk [0:15];     // cells BELOW nos")
    B.append("    reg [4:0] dsp;                 // count of spilled cells")
    B.append("    reg [4:0] depth;               // total items (tos+nos+spill)")
    B.append("")
    B.append("    // ---- return stack (separate, the dual-stack signature) ------------")
    B.append("    reg [7:0] rstk [0:7];")
    B.append("    reg [3:0] rsp;")
    B.append("")
    B.append(f"    reg [{w-1}:0] dmem [0:31];")
    B.append("")
    B.append("    wire [3:0]  op    = imem_data[15:12];")
    B.append("    wire [11:0] imm12 = imem_data[11:0];")
    B.append(f"    wire [{w-1}:0] pushv = {pim};   // PUSHI value")
    B.append("")
    B.append("    wire is_pushi = (op == 4'h0);")
    B.append("    wire is_load  = (op == 4'h1);")
    B.append("    wire is_store = (op == 4'h2);")
    B.append("    wire is_binop = (op >= 4'h3) && (op <= 4'h7);")
    B.append("    wire is_dup   = (op == 4'h8);")
    B.append("    wire is_drop  = (op == 4'h9);")
    B.append("    wire is_swap  = (op == 4'hA);")
    B.append("    wire is_over  = (op == 4'hB);")
    B.append("    wire is_jmp   = (op == 4'hC);")
    B.append("    wire is_jz    = (op == 4'hD);")
    B.append("    wire is_call  = (op == 4'hE);")
    B.append("    wire is_misc  = (op == 4'hF);")
    B.append("    wire is_ret   = is_misc && (imm12[1:0] == 2'd0);")
    B.append("    wire is_out   = is_misc && (imm12[1:0] == 2'd1);")
    B.append("    wire is_hlt   = is_misc && (imm12[1:0] == 2'd2);")
    B.append("")
    B.append("    // ---- ALU on the two top cells (operand-isolated) ------------------")
    B.append(f"    wire [{w-1}:0] al_a = nos & {{{w}{{is_binop}}}};")
    B.append(f"    wire [{w-1}:0] al_b = tos & {{{w}{{is_binop}}}};")
    B.append(f"    wire [{w-1}:0] al_y = (op == 4'h3) ? (al_a + al_b)")
    B.append("                        : (op == 4'h4) ? (al_a - al_b)")
    B.append("                        : (op == 4'h5) ? (al_a & al_b)")
    B.append("                        : (op == 4'h6) ? (al_a | al_b)")
    B.append("                        :                (al_a ^ al_b);")
    B.append("")
    B.append(f"    wire [{w-1}:0] third = dstk[dsp[3:0] - 4'd1];   // cell under NOS")
    B.append(f"    wire tos_zero = (tos == {{{w}{{1'b0}}}});")
    B.append("")
    B.append("    assign imem_addr = pc;")
    B.append("    assign dbg_pc    = pc;")
    B.append("    assign dbg_tos   = tos;")
    B.append("    assign dbg_depth = depth;")
    B.append("")
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
    B.append("                    dstk[dsp[3:0]] <= nos;")
    B.append("                    if (depth >= 5'd2) dsp <= dsp + 5'd1;")
    B.append("                    nos <= tos;")
    B.append("                    tos <= is_load ? dmem[imm12[4:0]] : pushv;")
    B.append("                    depth <= depth + 5'd1;")
    B.append("                end")
    B.append("                4'h8: begin              // DUP = push(tos)")
    B.append("                    dstk[dsp[3:0]] <= nos;")
    B.append("                    if (depth >= 5'd2) dsp <= dsp + 5'd1;")
    B.append("                    nos <= tos;")
    B.append("                    depth <= depth + 5'd1;")
    B.append("                end")
    B.append("                4'hB: begin              // OVER = push(nos)")
    B.append("                    dstk[dsp[3:0]] <= nos;")
    B.append("                    if (depth >= 5'd2) dsp <= dsp + 5'd1;")
    B.append("                    tos <= nos;")
    B.append("                    nos <= tos;")
    B.append("                    depth <= depth + 5'd1;")
    B.append("                end")
    B.append("                // ---- pops: refill nos from spill RAM --------------------")
    B.append("                4'h2, 4'h9: begin        // STORE / DROP (pop one)")
    B.append("                    if (is_store) dmem[imm12[4:0]] <= tos;")
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
    B.append("                    rstk[rsp[2:0]] <= pc + 8'd1;")
    B.append("                    rsp <= rsp + 4'd1;")
    B.append("                    pc  <= imm12[7:0];")
    B.append("                end")
    B.append("                4'hF: case (imm12[1:0])")
    B.append("                    2'd0: begin                          // RET")
    B.append("                        pc  <= rstk[rsp[2:0] - 3'd1];")
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

    write(os.path.join(OUT, name + ".v"),
          hdr + "\n" + ports + defs + "\n" + "\n".join(B) + "\n")


for w in CPU_WIDTHS:
    gen(w)
print("CPUs: stack-machine family generated")
