"""
gen_cpu_x86.py  ->  src/CPUs/cpu_x86_{4,8,16,32,64}.v

X86-FLAVOURED two-operand CISC machine (8086 lineage, teaching subset).
Single-cycle Harvard core, 16-bit instructions, data width W.

The defining CISC/x86 traits are kept:
  * TWO-OPERAND DESTRUCTIVE ops:  dst = dst OP src  (AX BX CX DX)
  * a FLAGS register (CF ZF SF OF) with the authentic quirks:
      - INC/DEC update ZF/SF/OF but PRESERVE CF
      - NOT touches no flags at all
      - logic ops clear CF/OF
      - ROL updates only CF/OF (ZF/SF untouched)
  * a descending stack in unified data RAM (PUSH POP CALL RET, SP init 32)
  * LOOP: the classic CX-decrement-and-branch in one instruction
  * condition-code jumps reading the FLAGS combinations (JL = SF^OF etc.)

INSTRUCTION WORD  [15:12]=op  [11:10]=r  [9:8]=m  [7:0]=imm8
  op 0  MOV  r, m            op 8  unary  (m: 0 INC 1 DEC 2 NOT 3 NEG)
  op 1  MOV  r, imm8         op 9  shift  (m: 0 SHL 1 SHR 2 SAR 3 ROL, by 1)
  op 2  ADD  r, m            op A  MOV r, [imm8]    (load,  addr = imm8[4:0])
  op 3  SUB  r, m            op B  MOV [imm8], r    (store)
  op 4  AND  r, m            op C  stack  (m: 0 PUSH r  1 POP r  2 CALL imm8  3 RET)
  op 5  OR   r, m            op D  Jcc imm8, cond = {r,m}:
  op 6  XOR  r, m                  0 JMP 1 JZ 2 JNZ 3 JC 4 JNC 5 JS 6 JNS
  op 7  CMP  r, m                  7 JO 8 JNO 9 JL 10 JGE 11 JG 12 JLE
                                   13 LOOP (CX--, jump while CX!=0) 14/15 never
                             op E  MOVH r, imm8 : r = (r<<8)|imm8  (const builder)
                             op F  misc (m: 0 NOP 1 HLT 2 OUT r 3 NOP)

Width-4 note: the unified RAM word is 4 bits, so CALL return addresses
truncate to 4 bits -- keep CALL/RET targets below address 16 on that core.
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write
from _cpu_common import CPU_WIDTHS, define_line

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "CPUs")


def gen(w):
    name = f"cpu_x86_{w}"
    s = w - 1   # sign bit index
    hdr = banner(f"{name}.v", [
        f"{w}-bit x86-FLAVOURED CISC CPU (two-operand destructive ISA).",
        "AX/BX/CX/DX + FLAGS(CF ZF SF OF) + SP, descending stack in a",
        "32-word unified data/stack RAM. Authentic flag quirks kept:",
        "INC/DEC preserve CF, NOT touches no flags, LOOP uses CX.",
        "16-bit Harvard instructions on imem_*. See docs/cpus.md.",
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
    input  wire [2:0]  dbg_sel,      // 0..3 AX..DX, 4 SP, 5 FLAGS, 6 PC
    output wire [{w-1}:0]  dbg_data,
    output wire [7:0]  dbg_pc
);
"""
    defs = define_line([
        ("clk", "input", "clk"), ("rst", "input", "rst"),
        ("imem_addr", "output", "imem_addr"), ("imem_data", "input", "imem_data"),
        ("out_data", "output", "out_data"), ("out_valid", "output", "out_valid"),
        ("halted", "output", "halted"),
        ("dbg_sel", "input", "dbg_sel"), ("dbg_data", "output", "dbg_data"),
        ("dbg_pc", "output", "dbg_pc"),
    ])

    def zx(expr, frm):
        if w == frm:
            return expr
        if w < frm:
            return f"{expr}[{w-1}:0]"
        return f"{{{{{w-frm}{{1'b0}}}}, {expr}}}"

    B = []
    B.append("    reg [7:0] pc;")
    B.append(f"    reg [{w-1}:0] regs [0:3];      // 0 AX, 1 BX, 2 CX, 3 DX")
    B.append(f"    reg [{w-1}:0] ram  [0:31];     // unified data + descending stack")
    B.append("    reg [5:0] sp;                  // stack pointer (init 32 = empty)")
    B.append("    reg cf, zf, sf, vf;            // FLAGS: carry zero sign overflow")
    B.append("")
    B.append("    wire [3:0] op   = imem_data[15:12];")
    B.append("    wire [1:0] rsel = imem_data[11:10];")
    B.append("    wire [1:0] msel = imem_data[9:8];")
    B.append("    wire [7:0] imm8 = imem_data[7:0];")
    B.append("    wire [3:0] cond = {rsel, msel};")
    B.append("")
    B.append(f"    wire [{w-1}:0] rv = regs[rsel];   // destination operand (read)")
    B.append(f"    wire [{w-1}:0] mv = regs[msel];   // source operand")
    B.append("")
    B.append("    // ---- class decode -------------------------------------------------")
    B.append("    wire is_movrr = (op == 4'h0);")
    B.append("    wire is_movi  = (op == 4'h1);")
    B.append("    wire is_add   = (op == 4'h2);")
    B.append("    wire is_sub   = (op == 4'h3);")
    B.append("    wire is_and   = (op == 4'h4);")
    B.append("    wire is_or    = (op == 4'h5);")
    B.append("    wire is_xor   = (op == 4'h6);")
    B.append("    wire is_cmp   = (op == 4'h7);")
    B.append("    wire is_unary = (op == 4'h8);")
    B.append("    wire is_shift = (op == 4'h9);")
    B.append("    wire is_load  = (op == 4'hA);")
    B.append("    wire is_store = (op == 4'hB);")
    B.append("    wire is_stk   = (op == 4'hC);")
    B.append("    wire is_jcc   = (op == 4'hD);")
    B.append("    wire is_movh  = (op == 4'hE);")
    B.append("    wire is_misc  = (op == 4'hF);")
    B.append("")
    B.append("    wire is_push = is_stk & (msel == 2'd0);")
    B.append("    wire is_pop  = is_stk & (msel == 2'd1);")
    B.append("    wire is_call = is_stk & (msel == 2'd2);")
    B.append("    wire is_ret  = is_stk & (msel == 2'd3);")
    B.append("    wire is_hlt  = is_misc & (msel == 2'd1);")
    B.append("    wire is_out  = is_misc & (msel == 2'd2);")
    B.append("    wire is_loop = is_jcc & (cond == 4'd13);")
    B.append("")
    B.append("    // ---- ALU (operand-isolated paths, flagship style) -----------------")
    B.append("    wire sel_arith = is_add | is_sub | is_cmp")
    B.append("                   | (is_unary & (msel != 2'd2));   // INC DEC NEG")
    B.append("    wire sel_logic = is_and | is_or | is_xor | (is_unary & (msel == 2'd2));")
    B.append("    wire sel_shift = is_shift;")
    B.append("")
    B.append("    // arithmetic path: y = a +/- b (+carry chain view for CF/OF)")
    B.append(f"    wire [{w-1}:0] ar_a = (is_unary ? ((msel == 2'd3) ? {{{w}{{1'b0}}}} : rv) : rv)")
    B.append(f"                        & {{{w}{{sel_arith}}}};")
    B.append(f"    wire [{w-1}:0] ar_b = (is_unary ? ((msel == 2'd3) ? rv : {{{{{w-1}{{1'b0}}}}, 1'b1}}) : mv)")
    B.append(f"                        & {{{w}{{sel_arith}}}};")
    B.append("    wire ar_subop = is_sub | is_cmp")
    B.append("                  | (is_unary & ((msel == 2'd1) | (msel == 2'd3))); // DEC NEG")
    B.append(f"    wire [{w}:0] ar_full = ar_subop ? ({{1'b0, ar_a}} - {{1'b0, ar_b}})")
    B.append(f"                                    : ({{1'b0, ar_a}} + {{1'b0, ar_b}});")
    B.append(f"    wire [{w-1}:0] ar_y = ar_full[{w-1}:0];")
    B.append(f"    wire ar_c = ar_full[{w}];                       // carry / borrow")
    B.append(f"    wire ar_v = ar_subop ? ((ar_a[{s}] != ar_b[{s}]) & (ar_y[{s}] != ar_a[{s}]))")
    B.append(f"                         : ((ar_a[{s}] == ar_b[{s}]) & (ar_y[{s}] != ar_a[{s}]));")
    B.append("")
    B.append("    // logic path")
    B.append(f"    wire [{w-1}:0] lg_a = rv & {{{w}{{sel_logic}}}};")
    B.append(f"    wire [{w-1}:0] lg_b = mv & {{{w}{{sel_logic}}}};")
    B.append(f"    wire [{w-1}:0] lg_y = is_and ? (lg_a & lg_b)")
    B.append("                        : is_or  ? (lg_a | lg_b)")
    B.append("                        : is_xor ? (lg_a ^ lg_b)")
    B.append("                        :          (~lg_a);          // NOT")
    B.append("")
    B.append("    // shift path (single position, x86 flag semantics)")
    B.append(f"    wire [{w-1}:0] sh_a = rv & {{{w}{{sel_shift}}}};")
    B.append(f"    wire [{w-1}:0] sh_y = (msel == 2'd0) ? {{sh_a[{w-2}:0], 1'b0}}        // SHL")
    B.append(f"                        : (msel == 2'd1) ? {{1'b0, sh_a[{w-1}:1]}}        // SHR")
    B.append(f"                        : (msel == 2'd2) ? {{sh_a[{s}], sh_a[{w-1}:1]}}    // SAR")
    B.append(f"                        :                  {{sh_a[{w-2}:0], sh_a[{s}]}};   // ROL")
    B.append(f"    wire sh_c = (msel == 2'd0) ? sh_a[{s}]")
    B.append("              : (msel == 2'd3) ? sh_a[%d]" % s)
    B.append("              :                  sh_a[0];")
    B.append(f"    wire sh_v = (msel == 2'd0) ? (sh_y[{s}] ^ sh_c)    // SHL: OF = CF^MSB(result)")
    B.append(f"              : (msel == 2'd1) ? sh_a[{s}]             // SHR: OF = old MSB")
    B.append(f"              : (msel == 2'd3) ? (sh_y[{s}] ^ sh_c)    // ROL")
    B.append("              :                  1'b0;                // SAR: OF = 0")
    B.append("")
    B.append("    // ---- condition evaluation (x86 Jcc table) -------------------------")
    B.append("    reg ctaken;")
    B.append("    always @(*) begin case (cond)")
    B.append("        4'd0:  ctaken = 1'b1;            // JMP")
    B.append("        4'd1:  ctaken = zf;              // JZ")
    B.append("        4'd2:  ctaken = ~zf;             // JNZ")
    B.append("        4'd3:  ctaken = cf;              // JC")
    B.append("        4'd4:  ctaken = ~cf;             // JNC")
    B.append("        4'd5:  ctaken = sf;              // JS")
    B.append("        4'd6:  ctaken = ~sf;             // JNS")
    B.append("        4'd7:  ctaken = vf;              // JO")
    B.append("        4'd8:  ctaken = ~vf;             // JNO")
    B.append("        4'd9:  ctaken = sf ^ vf;         // JL  (signed <)")
    B.append("        4'd10: ctaken = ~(sf ^ vf);      // JGE")
    B.append("        4'd11: ctaken = ~zf & ~(sf ^ vf);// JG")
    B.append("        4'd12: ctaken = zf | (sf ^ vf);  // JLE")
    B.append(f"        4'd13: ctaken = (regs[2] != {{{w}{{1'b0}}}});  // LOOP looks at CX-1... see EXEC")
    B.append("        default: ctaken = 1'b0;          // 14/15 never")
    B.append("    endcase end")
    B.append("")
    B.append(f"    wire [{w-1}:0] cx_dec = regs[2] - {{{{{w-1}{{1'b0}}}}, 1'b1}};")
    B.append(f"    wire loop_take = (cx_dec != {{{w}{{1'b0}}}});")
    B.append("")
    B.append(f"    wire [{w-1}:0] stk_top = ram[sp[4:0]];")
    B.append("    wire [7:0] pc1w = pc + 8'd1;       // return address (CALL)")
    B.append("")
    B.append("    assign imem_addr = pc;")
    B.append("    assign dbg_pc    = pc;")
    B.append(f"    assign dbg_data  = (dbg_sel < 3'd4) ? regs[dbg_sel[1:0]]")
    B.append(f"                     : (dbg_sel == 3'd4) ? {zx('sp', 6)}")
    B.append(f"                     : (dbg_sel == 3'd5) ? {zx("{vf, sf, zf, cf}", 4)}")
    B.append(f"                     :                    {zx('pc', 8)};")
    B.append("")
    B.append("    always @(posedge clk) begin")
    B.append("        out_valid <= 1'b0;")
    B.append("        if (rst) begin")
    B.append("            pc <= 8'd0; sp <= 6'd32; halted <= 1'b0;")
    B.append("            cf <= 1'b0; zf <= 1'b0; sf <= 1'b0; vf <= 1'b0;")
    B.append(f"            out_data <= {{{w}{{1'b0}}}};")
    B.append(f"            regs[0] <= {{{w}{{1'b0}}}}; regs[1] <= {{{w}{{1'b0}}}};")
    B.append(f"            regs[2] <= {{{w}{{1'b0}}}}; regs[3] <= {{{w}{{1'b0}}}};")
    B.append("        end else if (!halted) begin")
    B.append("            pc <= pc + 8'd1;            // default; flow ops override")
    B.append("            case (op)")
    B.append("                4'h0: regs[rsel] <= mv;                       // MOV r,m")
    B.append(f"                4'h1: regs[rsel] <= {zx('imm8', 8)};         // MOV r,imm8")
    B.append("                4'h2, 4'h3: begin                              // ADD SUB")
    B.append("                    regs[rsel] <= ar_y;")
    B.append(f"                    cf <= ar_c; zf <= (ar_y == {{{w}{{1'b0}}}});")
    B.append(f"                    sf <= ar_y[{s}]; vf <= ar_v;")
    B.append("                end")
    B.append("                4'h4, 4'h5, 4'h6: begin                        // AND OR XOR")
    B.append("                    regs[rsel] <= lg_y;")
    B.append(f"                    cf <= 1'b0; vf <= 1'b0;                    // x86: logic clears CF/OF")
    B.append(f"                    zf <= (lg_y == {{{w}{{1'b0}}}}); sf <= lg_y[{s}];")
    B.append("                end")
    B.append("                4'h7: begin                                    // CMP (flags only)")
    B.append(f"                    cf <= ar_c; zf <= (ar_y == {{{w}{{1'b0}}}});")
    B.append(f"                    sf <= ar_y[{s}]; vf <= ar_v;")
    B.append("                end")
    B.append("                4'h8: case (msel)                              // unary")
    B.append("                    2'd0, 2'd1: begin                          // INC DEC")
    B.append("                        regs[rsel] <= ar_y;                    // CF PRESERVED (x86 quirk)")
    B.append(f"                        zf <= (ar_y == {{{w}{{1'b0}}}}); sf <= ar_y[{s}]; vf <= ar_v;")
    B.append("                    end")
    B.append("                    2'd2: regs[rsel] <= lg_y;                  // NOT: no flags (x86 quirk)")
    B.append("                    2'd3: begin                                // NEG = 0 - r")
    B.append("                        regs[rsel] <= ar_y;")
    B.append(f"                        cf <= (rv != {{{w}{{1'b0}}}});            // x86: CF=0 only if src was 0")
    B.append(f"                        zf <= (ar_y == {{{w}{{1'b0}}}}); sf <= ar_y[{s}]; vf <= ar_v;")
    B.append("                    end")
    B.append("                endcase")
    B.append("                4'h9: begin                                    // shifts by 1")
    B.append("                    regs[rsel] <= sh_y;")
    B.append("                    cf <= sh_c; vf <= sh_v;")
    B.append("                    if (msel != 2'd3) begin                    // ROL: ZF/SF untouched")
    B.append(f"                        zf <= (sh_y == {{{w}{{1'b0}}}}); sf <= sh_y[{s}];")
    B.append("                    end")
    B.append("                end")
    B.append("                4'hA: regs[rsel] <= ram[imm8[4:0]];            // MOV r,[imm8]")
    B.append("                4'hB: ram[imm8[4:0]] <= rv;                    // MOV [imm8],r")
    B.append("                4'hC: case (msel)")
    B.append("                    2'd0: begin ram[sp[4:0] - 5'd1] <= rv; sp <= sp - 6'd1; end // PUSH")
    B.append("                    2'd1: begin regs[rsel] <= stk_top; sp <= sp + 6'd1; end     // POP")
    B.append("                    2'd2: begin                                                 // CALL")
    ret_expr = zx("pc1w", 8)
    B.append(f"                        ram[sp[4:0] - 5'd1] <= {ret_expr};")
    B.append("                        sp <= sp - 6'd1; pc <= imm8;")
    B.append("                    end")
    B.append("                    2'd3: begin pc <= " + ("stk_top[7:0]" if w >= 8 else "{4'd0, stk_top}") + "; sp <= sp + 6'd1; end // RET")
    B.append("                endcase")
    B.append("                4'hD: begin                                    // Jcc / LOOP")
    B.append("                    if (is_loop) begin")
    B.append("                        regs[2] <= cx_dec;                     // CX-- (no flags)")
    B.append("                        if (loop_take) pc <= imm8;")
    B.append("                    end else if (ctaken) pc <= imm8;")
    B.append("                end")
    if w >= 16:
        B.append(f"                4'hE: regs[rsel] <= {{rv[{w-9}:0], imm8}};     // MOVH (shift-in byte)")
    elif w == 8:
        B.append("                4'hE: regs[rsel] <= imm8;                      // MOVH == MOV on W=8")
    else:
        B.append("                4'hE: regs[rsel] <= imm8[3:0];                 // MOVH == MOV on W=4")
    B.append("                4'hF: case (msel)")
    B.append("                    2'd1: begin halted <= 1'b1; pc <= pc; end      // HLT")
    B.append("                    2'd2: begin out_data <= rv; out_valid <= 1'b1; end // OUT")
    B.append("                    default: ;                                     // NOP")
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
print("CPUs: x86-flavoured CISC family generated")
