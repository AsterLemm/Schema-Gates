"""
gen_cpu_x86.py  ->  src/CPUs/cpu_x86_{4,8,16,32,64}.v

x86-FLAVOURED CISC CPU (two-operand destructive ISA, teaching subset).
Single-cycle Harvard core, 16-bit instructions, data width W.

The defining x86 traits are kept:
  * two-operand DESTRUCTIVE ops: r op= m (result overwrites operand 1)
  * 4 named registers AX BX CX DX + FLAGS + SP (no flat register file)
  * a descending stack in memory with PUSH/POP/CALL/RET through SP
  * authentic FLAGS quirks: INC/DEC preserve CF, NOT touches no flags,
    NEG sets CF unless the source was zero, logic ops clear CF/OF,
    rotates touch only CF/OF
  * LOOP: CX-- and branch while CX != 0
  * rich Jcc set evaluated from ZF/CF/SF/OF

INSTRUCTION WORD
  [15:12]=op [11:10]=r [9:8]=m [7:0]=imm8       cond = {r, m}
  op 0 MOV r,m   1 MOV r,imm8   2 ADD r,m   3 SUB r,m
     4 AND r,m   5 OR r,m       6 XOR r,m   7 CMP r,m
     8 unary (m: 0 INC 1 DEC 2 NOT 3 NEG)
     9 shift1 (m: 0 SHL 1 SHR 2 SAR 3 ROL)
     A MOV r,[imm8]   B MOV [imm8],r
     C stack (m: 0 PUSH r  1 POP r  2 CALL imm8  3 RET)
     D Jcc imm8 (cond: 0 JMP 1 JZ 2 JNZ 3 JC 4 JNC 5 JS 6 JNS 7 JO
                 8 JNO 9 JL 10 JGE 11 JG 12 JLE 13 LOOP)
     E MOVH r,imm8 (shift imm8 into the low byte: r = {r[W-9:0], imm8})
     F misc (m: 1 HLT  2 OUT r)

MODULAR EMISSION (DigitalJS-style hierarchy): <top>_decode / _cond /
_alu (instantiating _alu_arith + _alu_logic + _alu_shift) / _regfile /
_ram / _flags / _wbsel / _pcnext submodules; pc/sp/out/halt sequencing
stays in the top. Every expression is carried over verbatim from the
monolithic emitter, so behaviour is identical.
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write
from _cpu_common import CPU_WIDTHS, define_line

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "CPUs")


def decode_module(n):
    return f"""\
// --- {n}_decode : fields + instruction class decode ---
module {n}_decode(
    input  wire [15:0] ir,
    output wire [3:0]  op,
    output wire [1:0]  rsel,
    output wire [1:0]  msel,
    output wire [7:0]  imm8,
    output wire [3:0]  cond,
    output wire        is_movrr,
    output wire        is_movi,
    output wire        is_add,
    output wire        is_sub,
    output wire        is_and,
    output wire        is_or,
    output wire        is_xor,
    output wire        is_cmp,
    output wire        is_unary,
    output wire        is_shift,
    output wire        is_load,
    output wire        is_store,
    output wire        is_stk,
    output wire        is_jcc,
    output wire        is_movh,
    output wire        is_misc,
    output wire        is_push,
    output wire        is_pop,
    output wire        is_call,
    output wire        is_ret,
    output wire        is_hlt,
    output wire        is_out,
    output wire        is_loop,
    output wire        sel_arith,
    output wire        sel_logic,
    output wire        sel_shift
);
    assign op   = ir[15:12];
    assign rsel = ir[11:10];
    assign msel = ir[9:8];
    assign imm8 = ir[7:0];
    assign cond = {{rsel, msel}};

    // ---- class decode -------------------------------------------------
    assign is_movrr = (op == 4'h0);
    assign is_movi = (op == 4'h1);
    assign is_add = (op == 4'h2);
    assign is_sub = (op == 4'h3);
    assign is_and = (op == 4'h4);
    assign is_or = (op == 4'h5);
    assign is_xor = (op == 4'h6);
    assign is_cmp = (op == 4'h7);
    assign is_unary = (op == 4'h8);
    assign is_shift = (op == 4'h9);
    assign is_load = (op == 4'hA);
    assign is_store = (op == 4'hB);
    assign is_stk = (op == 4'hC);
    assign is_jcc = (op == 4'hD);
    assign is_movh = (op == 4'hE);
    assign is_misc = (op == 4'hF);

    assign is_push = is_stk & (msel == 2'd0);
    assign is_pop = is_stk & (msel == 2'd1);
    assign is_call = is_stk & (msel == 2'd2);
    assign is_ret = is_stk & (msel == 2'd3);
    assign is_hlt = is_misc & (msel == 2'd1);
    assign is_out = is_misc & (msel == 2'd2);
    assign is_loop = is_jcc & (cond == 4'd13);

    assign sel_arith = is_add | is_sub | is_cmp
                   | (is_unary & (msel != 2'd2));   // INC DEC NEG
    assign sel_logic = is_and | is_or | is_xor | (is_unary & (msel == 2'd2));
    assign sel_shift = is_shift;
endmodule"""


def alu_arith_module(n, w):
    s = w - 1
    return f"""\
// --- {n}_alu_arith : add/sub path with carry-chain CF/OF view ---
// (leaf of {n}_alu)
module {n}_alu_arith(
    input  wire [{w-1}:0] ar_a,
    input  wire [{w-1}:0] ar_b,
    input  wire        ar_subop,
    output wire [{w-1}:0] ar_y,
    output wire        ar_c,
    output wire        ar_v
);
    wire [{w}:0] ar_full = ar_subop ? ({{1'b0, ar_a}} - {{1'b0, ar_b}})
                                    : ({{1'b0, ar_a}} + {{1'b0, ar_b}});
    assign ar_y = ar_full[{w-1}:0];
    assign ar_c = ar_full[{w}];                       // carry / borrow
    assign ar_v = ar_subop ? ((ar_a[{s}] != ar_b[{s}]) & (ar_y[{s}] != ar_a[{s}]))
                         : ((ar_a[{s}] == ar_b[{s}]) & (ar_y[{s}] != ar_a[{s}]));
endmodule"""


def alu_logic_module(n, w):
    return f"""\
// --- {n}_alu_logic : AND / OR / XOR / NOT path (leaf of {n}_alu) ---
module {n}_alu_logic(
    input  wire [{w-1}:0] lg_a,
    input  wire [{w-1}:0] lg_b,
    input  wire        is_and,
    input  wire        is_or,
    input  wire        is_xor,
    output wire [{w-1}:0] lg_y
);
    assign lg_y = is_and ? (lg_a & lg_b)
                : is_or  ? (lg_a | lg_b)
                : is_xor ? (lg_a ^ lg_b)
                :          (~lg_a);          // NOT
endmodule"""


def alu_shift_module(n, w):
    s = w - 1
    return f"""\
// --- {n}_alu_shift : single-position shifts, x86 flag semantics ---
// (leaf of {n}_alu)
module {n}_alu_shift(
    input  wire [{w-1}:0] sh_a,
    input  wire [1:0]  msel,
    output wire [{w-1}:0] sh_y,
    output wire        sh_c,
    output wire        sh_v
);
    assign sh_y = (msel == 2'd0) ? {{sh_a[{w-2}:0], 1'b0}}        // SHL
                : (msel == 2'd1) ? {{1'b0, sh_a[{w-1}:1]}}        // SHR
                : (msel == 2'd2) ? {{sh_a[{s}], sh_a[{w-1}:1]}}    // SAR
                :                  {{sh_a[{w-2}:0], sh_a[{s}]}};   // ROL
    assign sh_c = (msel == 2'd0) ? sh_a[{s}]
              : (msel == 2'd3) ? sh_a[{s}]
              :                  sh_a[0];
    assign sh_v = (msel == 2'd0) ? (sh_y[{s}] ^ sh_c)    // SHL: OF = CF^MSB(result)
              : (msel == 2'd1) ? sh_a[{s}]             // SHR: OF = old MSB
              : (msel == 2'd3) ? (sh_y[{s}] ^ sh_c)    // ROL
              :                  1'b0;                // SAR: OF = 0
endmodule"""


def alu_module(n, w):
    return f"""\
// --- {n}_alu : operand-isolated 3-path ALU (flagship technique) ---
// operand muxes for the unary ops (INC/DEC use +/-1, NEG uses 0-r)
// live here; each path's inputs are ANDed with its select line.
module {n}_alu(
    input  wire [{w-1}:0] rv,
    input  wire [{w-1}:0] mv,
    input  wire [1:0]  msel,
    input  wire        is_sub,
    input  wire        is_cmp,
    input  wire        is_unary,
    input  wire        is_and,
    input  wire        is_or,
    input  wire        is_xor,
    input  wire        sel_arith,
    input  wire        sel_logic,
    input  wire        sel_shift,
    output wire [{w-1}:0] ar_y,
    output wire        ar_c,
    output wire        ar_v,
    output wire [{w-1}:0] lg_y,
    output wire [{w-1}:0] sh_y,
    output wire        sh_c,
    output wire        sh_v
);
    // arithmetic path: y = a +/- b (+carry chain view for CF/OF)
    wire [{w-1}:0] ar_a = (is_unary ? ((msel == 2'd3) ? {{{w}{{1'b0}}}} : rv) : rv)
                        & {{{w}{{sel_arith}}}};
    wire [{w-1}:0] ar_b = (is_unary ? ((msel == 2'd3) ? rv : {{{{{w-1}{{1'b0}}}}, 1'b1}}) : mv)
                        & {{{w}{{sel_arith}}}};
    wire ar_subop = is_sub | is_cmp
                  | (is_unary & ((msel == 2'd1) | (msel == 2'd3))); // DEC NEG
    {n}_alu_arith u_arith(.ar_a(ar_a), .ar_b(ar_b), .ar_subop(ar_subop),
                          .ar_y(ar_y), .ar_c(ar_c), .ar_v(ar_v));

    // logic path
    wire [{w-1}:0] lg_a = rv & {{{w}{{sel_logic}}}};
    wire [{w-1}:0] lg_b = mv & {{{w}{{sel_logic}}}};
    {n}_alu_logic u_logic(.lg_a(lg_a), .lg_b(lg_b),
                          .is_and(is_and), .is_or(is_or), .is_xor(is_xor),
                          .lg_y(lg_y));

    // shift path (single position, x86 flag semantics)
    wire [{w-1}:0] sh_a = rv & {{{w}{{sel_shift}}}};
    {n}_alu_shift u_shift(.sh_a(sh_a), .msel(msel),
                          .sh_y(sh_y), .sh_c(sh_c), .sh_v(sh_v));
endmodule"""


def cond_module(n, w):
    return f"""\
// --- {n}_cond : x86 Jcc condition table ---
module {n}_cond(
    input  wire [3:0]  cond,
    input  wire        zf,
    input  wire        cf,
    input  wire        sf,
    input  wire        vf,
    input  wire [{w-1}:0] cxv,
    output reg         ctaken
);
    always @(*) begin case (cond)
        4'd0:  ctaken = 1'b1;            // JMP
        4'd1:  ctaken = zf;              // JZ
        4'd2:  ctaken = ~zf;             // JNZ
        4'd3:  ctaken = cf;              // JC
        4'd4:  ctaken = ~cf;             // JNC
        4'd5:  ctaken = sf;              // JS
        4'd6:  ctaken = ~sf;             // JNS
        4'd7:  ctaken = vf;              // JO
        4'd8:  ctaken = ~vf;             // JNO
        4'd9:  ctaken = sf ^ vf;         // JL  (signed <)
        4'd10: ctaken = ~(sf ^ vf);      // JGE
        4'd11: ctaken = ~zf & ~(sf ^ vf);// JG
        4'd12: ctaken = zf | (sf ^ vf);  // JLE
        4'd13: ctaken = (cxv != {{{w}{{1'b0}}}});  // LOOP looks at CX-1... see EXEC
        default: ctaken = 1'b0;          // 14/15 never
    endcase end
endmodule"""


def regfile_module(n, w):
    return f"""\
// --- {n}_regfile : AX/BX/CX/DX (single muxed write port) ---
// all writing instruction classes are mutually exclusive, so one
// port (driven by {n}_wbsel) carries every result; LOOP writes CX.
module {n}_regfile(
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [1:0]  waddr,
    input  wire [{w-1}:0] wdata,
    input  wire [1:0]  rsel,
    input  wire [1:0]  msel,
    output wire [{w-1}:0] rv,
    output wire [{w-1}:0] mv,
    output wire [{w-1}:0] cxv,
    input  wire [1:0]  dbg_sel,
    output wire [{w-1}:0] dbg_data
);
    reg [{w-1}:0] regs [0:3];      // 0 AX, 1 BX, 2 CX, 3 DX

    assign rv = regs[rsel];   // destination operand (read)
    assign mv = regs[msel];   // source operand
    assign cxv = regs[2];     // LOOP counter
    assign dbg_data = regs[dbg_sel];

    // sync reset clears all four, exactly as before (no async edge)
    always @(posedge clk) begin
        if (rst) begin
            regs[0] <= {{{w}{{1'b0}}}}; regs[1] <= {{{w}{{1'b0}}}};
            regs[2] <= {{{w}{{1'b0}}}}; regs[3] <= {{{w}{{1'b0}}}};
        end else if (we) regs[waddr] <= wdata;
    end
endmodule"""


def ram_module(n, w):
    return f"""\
// --- {n}_ram : 32-word unified data + descending stack RAM ---
// one muxed write port (MOV [imm8],r / PUSH / CALL are exclusive),
// two async read ports (stack top at sp, data at imm8).
module {n}_ram(
    input  wire        clk,
    input  wire        we,
    input  wire [4:0]  waddr,
    input  wire [{w-1}:0] wdata,
    input  wire [4:0]  raddr_s,
    input  wire [4:0]  raddr_i,
    output wire [{w-1}:0] rdata_s,
    output wire [{w-1}:0] rdata_i
);
    reg [{w-1}:0] ram [0:31];     // unified data + descending stack

    assign rdata_s = ram[raddr_s];
    assign rdata_i = ram[raddr_i];

    // sync write only (no async edge: keeps the array ONE $mem cell)
    always @(posedge clk) begin
        if (we) ram[waddr] <= wdata;
    end
endmodule"""


def wbsel_module(n, w):
    if w >= 16:
        movh = f"{{rv[{w-9}:0], imm8}}"
        movh_c = "// MOVH (shift-in byte)"
    elif w == 8:
        movh = "imm8"
        movh_c = "// MOVH == MOV on W=8"
    else:
        movh = "imm8[3:0]"
        movh_c = "// MOVH == MOV on W=4"
    if w == 8:
        imm8x = "imm8"
    elif w < 8:
        imm8x = f"imm8[{w-1}:0]"
    else:
        imm8x = f"{{{{{w-8}{{1'b0}}}}, imm8}}"
    return f"""\
// --- {n}_wbsel : register write-back select (one port, many sources) ---
module {n}_wbsel(
    input  wire        is_movrr,
    input  wire        is_movi,
    input  wire        is_add,
    input  wire        is_sub,
    input  wire        is_and,
    input  wire        is_or,
    input  wire        is_xor,
    input  wire        is_unary,
    input  wire        is_shift,
    input  wire        is_load,
    input  wire        is_pop,
    input  wire        is_loop,
    input  wire        is_movh,
    input  wire [1:0]  msel,
    input  wire [1:0]  rsel,
    input  wire [7:0]  imm8,
    input  wire [{w-1}:0] rv,
    input  wire [{w-1}:0] mv,
    input  wire [{w-1}:0] ar_y,
    input  wire [{w-1}:0] lg_y,
    input  wire [{w-1}:0] sh_y,
    input  wire [{w-1}:0] ram_rd,
    input  wire [{w-1}:0] stk_top,
    input  wire [{w-1}:0] cx_dec,
    output wire        wb_en,
    output wire [1:0]  wb_addr,
    output wire [{w-1}:0] wb_data
);
    // every register-writing arm of the old EXEC case, one-hot by op
    assign wb_en = is_movrr | is_movi | is_add | is_sub
                 | is_and | is_or | is_xor
                 | is_unary | is_shift | is_load
                 | is_pop | is_loop | is_movh;
    assign wb_addr = is_loop ? 2'd2 : rsel;            // LOOP: CX--
    assign wb_data = is_movrr ? mv                                // MOV r,m
                   : is_movi  ? {imm8x}         // MOV r,imm8
                   : (is_add | is_sub) ? ar_y                     // ADD SUB
                   : (is_and | is_or | is_xor) ? lg_y             // AND OR XOR
                   : is_unary ? ((msel == 2'd2) ? lg_y : ar_y)    // NOT vs INC/DEC/NEG
                   : is_shift ? sh_y                              // shifts by 1
                   : is_load  ? ram_rd                            // MOV r,[imm8]
                   : is_pop   ? stk_top                           // POP r
                   : is_loop  ? cx_dec                            // CX-- (no flags)
                   :            {movh};     {movh_c}
endmodule"""


def flags_module(n, w):
    s = w - 1
    return f"""\
// --- {n}_flags : CF ZF SF OF with the authentic x86 quirks ---
// INC/DEC preserve CF; NOT touches no flags; NEG CF=0 only if src was 0;
// logic ops clear CF/OF; rotates leave ZF/SF untouched.
module {n}_flags(
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [3:0]  op,
    input  wire [1:0]  msel,
    input  wire [{w-1}:0] rv,
    input  wire [{w-1}:0] ar_y,
    input  wire        ar_c,
    input  wire        ar_v,
    input  wire [{w-1}:0] lg_y,
    input  wire [{w-1}:0] sh_y,
    input  wire        sh_c,
    input  wire        sh_v,
    output reg         cf,
    output reg         zf,
    output reg         sf,
    output reg         vf
);
    always @(posedge clk) begin
        if (rst) begin
            cf <= 1'b0; zf <= 1'b0; sf <= 1'b0; vf <= 1'b0;
        end else if (we) begin
            case (op)
                4'h2, 4'h3: begin                              // ADD SUB
                    cf <= ar_c; zf <= (ar_y == {{{w}{{1'b0}}}});
                    sf <= ar_y[{s}]; vf <= ar_v;
                end
                4'h4, 4'h5, 4'h6: begin                        // AND OR XOR
                    cf <= 1'b0; vf <= 1'b0;                    // x86: logic clears CF/OF
                    zf <= (lg_y == {{{w}{{1'b0}}}}); sf <= lg_y[{s}];
                end
                4'h7: begin                                    // CMP (flags only)
                    cf <= ar_c; zf <= (ar_y == {{{w}{{1'b0}}}});
                    sf <= ar_y[{s}]; vf <= ar_v;
                end
                4'h8: case (msel)                              // unary
                    2'd0, 2'd1: begin                          // INC DEC
                        zf <= (ar_y == {{{w}{{1'b0}}}}); sf <= ar_y[{s}]; vf <= ar_v;
                    end                                        // CF PRESERVED (x86 quirk)
                    2'd2: ;                                    // NOT: no flags (x86 quirk)
                    2'd3: begin                                // NEG = 0 - r
                        cf <= (rv != {{{w}{{1'b0}}}});            // x86: CF=0 only if src was 0
                        zf <= (ar_y == {{{w}{{1'b0}}}}); sf <= ar_y[{s}]; vf <= ar_v;
                    end
                endcase
                4'h9: begin                                    // shifts by 1
                    cf <= sh_c; vf <= sh_v;
                    if (msel != 2'd3) begin                    // ROL: ZF/SF untouched
                        zf <= (sh_y == {{{w}{{1'b0}}}}); sf <= sh_y[{s}];
                    end
                end
                default: ;
            endcase
        end
    end
endmodule"""


def pcnext_module(n, w):
    ret_t = "stk_top[7:0]" if w >= 8 else "{4'd0, stk_top}"
    return f"""\
// --- {n}_pcnext : next-PC select (default +1; flow ops override) ---
module {n}_pcnext(
    input  wire [7:0]  pc,
    input  wire [7:0]  imm8,
    input  wire [{w-1}:0] stk_top,
    input  wire        is_call,
    input  wire        is_ret,
    input  wire        is_jcc,
    input  wire        is_loop,
    input  wire        loop_take,
    input  wire        ctaken,
    input  wire        is_hlt,
    output wire [7:0]  next_pc
);
    wire [7:0] pc1w = pc + 8'd1;
    assign next_pc = is_call ? imm8
                   : is_ret  ? {ret_t}
                   : (is_jcc & (is_loop ? loop_take : ctaken)) ? imm8
                   : is_hlt  ? pc
                   :           pc1w;
endmodule"""


def gen(w):
    name = f"cpu_x86_{w}"
    hdr = banner(f"{name}.v", [
        f"{w}-bit x86-FLAVOURED CISC CPU (two-operand destructive ISA).",
        "AX/BX/CX/DX + FLAGS(CF ZF SF OF) + SP, descending stack in a",
        "32-word unified data/stack RAM. Authentic flag quirks kept:",
        "INC/DEC preserve CF, NOT touches no flags, LOOP uses CX.",
        "16-bit Harvard instructions on imem_*. See docs/cpus.md.",
        "MODULAR: decode / cond / ALU(arith+logic+shift) / regfile / ram /",
        "flags / wbsel / pcnext submodules; pc/sp/out/halt stay in the top.",
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

    mods = [decode_module(name), alu_arith_module(name, w),
            alu_logic_module(name, w), alu_shift_module(name, w),
            alu_module(name, w), cond_module(name, w),
            regfile_module(name, w), ram_module(name, w),
            wbsel_module(name, w), flags_module(name, w),
            pcnext_module(name, w)]

    B = []
    B.append("    reg [7:0] pc;")
    B.append("    reg [5:0] sp;                  // stack pointer (init 32 = empty)")
    B.append("")
    B.append("    // ---- decode ------------------------------------------------------")
    B.append("    wire [3:0] op, cond;")
    B.append("    wire [1:0] rsel, msel;")
    B.append("    wire [7:0] imm8;")
    B.append("    wire is_movrr, is_movi, is_add, is_sub, is_and, is_or, is_xor;")
    B.append("    wire is_cmp, is_unary, is_shift, is_load, is_store, is_stk;")
    B.append("    wire is_jcc, is_movh, is_misc;")
    B.append("    wire is_push, is_pop, is_call, is_ret, is_hlt, is_out, is_loop;")
    B.append("    wire sel_arith, sel_logic, sel_shift;")
    B.append(f"    {name}_decode u_decode(")
    B.append("        .ir(imem_data),")
    B.append("        .op(op), .rsel(rsel), .msel(msel), .imm8(imm8), .cond(cond),")
    B.append("        .is_movrr(is_movrr), .is_movi(is_movi), .is_add(is_add),")
    B.append("        .is_sub(is_sub), .is_and(is_and), .is_or(is_or),")
    B.append("        .is_xor(is_xor), .is_cmp(is_cmp), .is_unary(is_unary),")
    B.append("        .is_shift(is_shift), .is_load(is_load), .is_store(is_store),")
    B.append("        .is_stk(is_stk), .is_jcc(is_jcc), .is_movh(is_movh),")
    B.append("        .is_misc(is_misc),")
    B.append("        .is_push(is_push), .is_pop(is_pop), .is_call(is_call),")
    B.append("        .is_ret(is_ret), .is_hlt(is_hlt), .is_out(is_out),")
    B.append("        .is_loop(is_loop),")
    B.append("        .sel_arith(sel_arith), .sel_logic(sel_logic),")
    B.append("        .sel_shift(sel_shift)")
    B.append("    );")
    B.append("")
    B.append("    // write gating: identical condition to the old monolithic block")
    B.append("    // (writes happened only in the `else if (!halted)` branch).")
    B.append("    wire wr_gate = ~rst & ~halted;")
    B.append("")
    B.append("    // ---- register file + write-back select ---------------------------")
    B.append(f"    wire [{w-1}:0] rv, mv, cxv, rf_dbg;")
    B.append(f"    wire [{w-1}:0] ar_y, lg_y, sh_y, ram_rd, stk_top;")
    B.append("    wire ar_c, ar_v, sh_c, sh_v;")
    B.append(f"    wire [{w-1}:0] cx_dec = cxv - {{{{{w-1}{{1'b0}}}}, 1'b1}};")
    B.append(f"    wire loop_take = (cx_dec != {{{w}{{1'b0}}}});")
    B.append("    wire wb_en;")
    B.append("    wire [1:0] wb_addr;")
    B.append(f"    wire [{w-1}:0] wb_data;")
    B.append(f"    {name}_wbsel u_wbsel(")
    B.append("        .is_movrr(is_movrr), .is_movi(is_movi), .is_add(is_add),")
    B.append("        .is_sub(is_sub), .is_and(is_and), .is_or(is_or),")
    B.append("        .is_xor(is_xor), .is_unary(is_unary), .is_shift(is_shift),")
    B.append("        .is_load(is_load), .is_pop(is_pop), .is_loop(is_loop),")
    B.append("        .is_movh(is_movh),")
    B.append("        .msel(msel), .rsel(rsel), .imm8(imm8),")
    B.append("        .rv(rv), .mv(mv), .ar_y(ar_y), .lg_y(lg_y), .sh_y(sh_y),")
    B.append("        .ram_rd(ram_rd), .stk_top(stk_top), .cx_dec(cx_dec),")
    B.append("        .wb_en(wb_en), .wb_addr(wb_addr), .wb_data(wb_data)")
    B.append("    );")
    B.append(f"    {name}_regfile u_regfile(")
    B.append("        .clk(clk), .rst(rst),")
    B.append("        .we(wr_gate & wb_en), .waddr(wb_addr), .wdata(wb_data),")
    B.append("        .rsel(rsel), .msel(msel),")
    B.append("        .rv(rv), .mv(mv), .cxv(cxv),")
    B.append("        .dbg_sel(dbg_sel[1:0]), .dbg_data(rf_dbg)")
    B.append("    );")
    B.append("")
    B.append("    // ---- ALU (operand-isolated paths inside) ------------------------")
    B.append(f"    {name}_alu u_alu(")
    B.append("        .rv(rv), .mv(mv), .msel(msel),")
    B.append("        .is_sub(is_sub), .is_cmp(is_cmp), .is_unary(is_unary),")
    B.append("        .is_and(is_and), .is_or(is_or), .is_xor(is_xor),")
    B.append("        .sel_arith(sel_arith), .sel_logic(sel_logic),")
    B.append("        .sel_shift(sel_shift),")
    B.append("        .ar_y(ar_y), .ar_c(ar_c), .ar_v(ar_v),")
    B.append("        .lg_y(lg_y),")
    B.append("        .sh_y(sh_y), .sh_c(sh_c), .sh_v(sh_v)")
    B.append("    );")
    B.append("")
    B.append("    // ---- FLAGS unit ---------------------------------------------------")
    B.append("    wire cf, zf, sf, vf;")
    B.append(f"    {name}_flags u_flags(")
    B.append("        .clk(clk), .rst(rst), .we(wr_gate),")
    B.append("        .op(op), .msel(msel), .rv(rv),")
    B.append("        .ar_y(ar_y), .ar_c(ar_c), .ar_v(ar_v),")
    B.append("        .lg_y(lg_y), .sh_y(sh_y), .sh_c(sh_c), .sh_v(sh_v),")
    B.append("        .cf(cf), .zf(zf), .sf(sf), .vf(vf)")
    B.append("    );")
    B.append("")
    B.append("    // ---- condition evaluation (x86 Jcc table) -------------------------")
    B.append("    wire ctaken;")
    B.append(f"    {name}_cond u_cond(")
    B.append("        .cond(cond), .zf(zf), .cf(cf), .sf(sf), .vf(vf),")
    B.append("        .cxv(cxv),")
    B.append("        .ctaken(ctaken)")
    B.append("    );")
    B.append("")
    B.append("    // ---- unified data + stack RAM ------------------------------------")
    B.append("    wire ram_we = wr_gate & (is_store | is_push | is_call);")
    B.append("    wire [4:0] ram_waddr = is_store ? imm8[4:0] : (sp[4:0] - 5'd1);")
    B.append(f"    wire [{w-1}:0] ram_wdata = is_call ? {zx('pc1w', 8)} : rv;")
    B.append(f"    {name}_ram u_ram(")
    B.append("        .clk(clk),")
    B.append("        .we(ram_we), .waddr(ram_waddr), .wdata(ram_wdata),")
    B.append("        .raddr_s(sp[4:0]), .raddr_i(imm8[4:0]),")
    B.append("        .rdata_s(stk_top), .rdata_i(ram_rd)")
    B.append("    );")
    B.append("")
    B.append("    // ---- next PC -------------------------------------------------------")
    B.append("    wire [7:0] pc1w = pc + 8'd1;       // return address (CALL)")
    B.append("    wire [7:0] next_pc;")
    B.append(f"    {name}_pcnext u_pcnext(")
    B.append("        .pc(pc), .imm8(imm8), .stk_top(stk_top),")
    B.append("        .is_call(is_call), .is_ret(is_ret), .is_jcc(is_jcc),")
    B.append("        .is_loop(is_loop), .loop_take(loop_take), .ctaken(ctaken),")
    B.append("        .is_hlt(is_hlt),")
    B.append("        .next_pc(next_pc)")
    B.append("    );")
    B.append("")
    B.append("    assign imem_addr = pc;")
    B.append("    assign dbg_pc    = pc;")
    B.append(f"    assign dbg_data  = (dbg_sel < 3'd4) ? rf_dbg")
    B.append(f"                     : (dbg_sel == 3'd4) ? {zx('sp', 6)}")
    B.append(f"                     : (dbg_sel == 3'd5) ? {zx("{vf, sf, zf, cf}", 4)}")
    B.append(f"                     :                    {zx('pc', 8)};")
    B.append("")
    B.append("    // sequencing: identical to the monolithic core; the regfile, ram")
    B.append("    // and flag writes moved into their modules with the same conditions.")
    B.append("    always @(posedge clk) begin")
    B.append("        out_valid <= 1'b0;")
    B.append("        if (rst) begin")
    B.append("            pc <= 8'd0; sp <= 6'd32; halted <= 1'b0;")
    B.append(f"            out_data <= {{{w}{{1'b0}}}};")
    B.append("        end else if (!halted) begin")
    B.append("            pc <= next_pc;")
    B.append("            sp <= (is_push | is_call) ? sp - 6'd1")
    B.append("                : (is_pop  | is_ret)  ? sp + 6'd1")
    B.append("                :                       sp;")
    B.append("            if (is_out) begin out_data <= rv; out_valid <= 1'b1; end")
    B.append("            if (is_hlt) halted <= 1'b1;")
    B.append("        end")
    B.append("    end")
    B.append("endmodule")

    text = (hdr + "\n" + "\n\n".join(mods) + "\n\n"
            + ports + defs + "\n" + "\n".join(B) + "\n")
    write(os.path.join(OUT, name + ".v"), text)


for w in CPU_WIDTHS:
    gen(w)
print("CPUs: x86-flavoured CISC family generated (modular)")
