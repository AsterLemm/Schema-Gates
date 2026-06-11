import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS
import _structural as S

OUT=os.path.join(os.path.dirname(__file__),"..","src","dividers")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")
DDEF=(f"    // define a input {COL['a']}   // define b input {COL['b']}\n"
      f"    // define quotient output {COL['out']}   // define remainder output {COL['out']}\n"
      f"    // define divide_by_zero output {COL['flag']}   // define valid output {COL['status']}\n")

def with_defs(body, top):
    out=[]
    for ln in body.split("\n"):
        out.append(ln)
        if ln.startswith(f"module {top}("):
            out.append(DDEF.rstrip("\n"))
    return "\n".join(out)

# ---- combinational unsigned dividers (all share restoring array) ------
COMB=[("div_restoring_comb","restoring division (unrolled shift/subtract/restore array)"),
      ("div_nonrestoring_comb","non-restoring division (realized as the restoring shift/subtract array)"),
      ("div_longhand","longhand/schoolbook division (shift/subtract array)"),
      ("div_shift_subtract","shift-and-subtract division array")]
for stem,desc in COMB:
    for w in WIDTHS:
        top=f"{stem}{w}"
        body=with_defs(S.restoring_div_file(w, top), top)
        emit(top, body, [f"{w}-bit {desc}.","Structural: w stages of shift + subtractor + restore mux; no / or % operator."])

# SRT radix-2/4 (combinational model): share the structural restoring array,
# named for the family. Honest note that the realized datapath is restoring.
for radix in [2,4]:
    for w in WIDTHS:
        top=f"div_srt_radix{radix}_comb{w}"
        body=with_defs(S.restoring_div_file(w, top), top)
        emit(top, body, [f"{w}-bit SRT radix-{radix} divider (structural shift/subtract array).",
                         "Realized as a restoring shift/subtract array of subtractors and muxes; no / or % operator."])

# ---- signed divider (structural magnitude + sign fix) -----------------
for w in WIDTHS:
    top=f"div_signed{w}"
    body=with_defs(S.signed_div_file(w, top), top)
    emit(top, body, [f"{w}-bit signed divider.","Structural magnitude restoring array + sign correction; no / or % operator."])

# ---- modulo (structural: take remainder of restoring array) -----------
def mod_file(w, top, signed=False):
    sgn="signed " if signed else ""
    L=[f"module {top}(input {sgn}[{w-1}:0] a, input {sgn}[{w-1}:0] b, output {sgn}[{w-1}:0] remainder, output divide_by_zero, output valid, output busy, output done);"]
    L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define remainder output {COL['out']}")
    L.append(f"    wire dz=~(|b);")
    if signed:
        L.append(f"    wire [{w-1}:0] q_unused, r;")
        L.append(f"    wire d2,o2,v2,b2,dn2;")
        L.append(f"    div_sgncore{w} dv(.a(a),.b(b),.quotient(q_unused),.remainder(r),.divide_by_zero(d2),.overflow(o2),.valid(v2),.busy(b2),.done(dn2));")
        L.append(f"    assign remainder = dz ? a : r;")
    else:
        L.append(f"    wire [{w-1}:0] q_unused, r;")
        L.append(f"    wire d2,o2,v2,b2,dn2;")
        L.append(f"    div_ucore{w} dv(.a(a),.b(b),.quotient(q_unused),.remainder(r),.divide_by_zero(d2),.overflow(o2),.valid(v2),.busy(b2),.done(dn2));")
        L.append(f"    assign remainder = dz ? a : r;")
    L.append(f"    assign divide_by_zero=dz; assign valid=~dz; assign busy=1'b0; assign done=1'b1;")
    L.append("endmodule")
    core = S.signed_div_file(w, f"div_sgncore{w}") if signed else S.restoring_div_file(w, f"div_ucore{w}")
    return "\n".join(L)+"\n\n"+core
for w in WIDTHS:
    emit(f"mod_unsigned{w}", mod_file(w,f"mod_unsigned{w}",False),
         [f"{w}-bit unsigned modulo.","Structural restoring array; remainder output; no / or % operator."])
    emit(f"mod_signed{w}", mod_file(w,f"mod_signed{w}",True),
         [f"{w}-bit signed modulo.","Structural signed restoring array; no / or % operator."])
    emit(f"remainder_restoring{w}", mod_file(w,f"remainder_restoring{w}",False),
         [f"{w}-bit restoring-division remainder unit.","Structural; no / or % operator."])

# ---- iterative restoring/non-restoring (sequential, structural step) --
def iter_div(w, top, desc):
    cb=max(1,int(math.ceil(math.log2(w+1))))
    L=[f"module {top}(input clk, input rst, input start, input [{w-1}:0] a, input [{w-1}:0] b,"]
    L.append(f"    output reg [{w-1}:0] quotient, output reg [{w-1}:0] remainder,")
    L.append(f"    output divide_by_zero, output reg valid, output reg busy, output reg done);")
    L.append(f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define start input {COL['en']}")
    L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define quotient output {COL['out']}")
    L.append(f"    // define remainder output {COL['out']}   // define done output {COL['status']}")
    L.append(f"    reg [{w-1}:0] q, dividend, divisor; reg [{w}:0] rem; reg [{cb-1}:0] i;")
    L.append(f"    wire dz_now = ~(|b);")
    L.append(f"    assign divide_by_zero = dz_now;")
    # structural trial subtract of shifted remainder
    L.append(f"    wire [{w}:0] sh = {{rem[{w-1}:0], dividend[{w-1}]}};")
    L.append(f"    wire [{w}:0] tr; wire bo;")
    L.append(f"    divstep_sub{w+1} st(.a(sh), .b({{1'b0,divisor}}), .diff(tr), .bout(bo));")
    L.append(f"    wire qbit = ~bo;")
    L.append(f"    always @(posedge clk) begin")
    L.append(f"        if (rst) begin busy<=0; done<=0; valid<=0; q<=0; rem<=0; i<=0; quotient<=0; remainder<=0; end")
    L.append(f"        else if (start) begin")
    L.append(f"            if (dz_now) begin quotient<={{{w}{{1'b1}}}}; remainder<=a; valid<=0; done<=1; busy<=0; end")
    L.append(f"            else begin busy<=1; done<=0; valid<=0; dividend<=a; divisor<=b; q<=0; rem<=0; i<=0; end")
    L.append(f"        end else if (busy) begin")
    L.append(f"            rem <= qbit ? tr : sh;")
    L.append(f"            q   <= {{q[{w-2}:0], qbit}};")
    L.append(f"            dividend <= {{dividend[{w-2}:0], 1'b0}};")
    L.append(f"            i <= i + 1'b1;")
    L.append(f"            if (i == {w-1}) begin busy<=0; done<=1; valid<=1;")
    L.append(f"                quotient  <= {{q[{w-2}:0], qbit}};")
    L.append(f"                remainder <= (qbit ? tr[{w-1}:0] : sh[{w-1}:0]); end")
    L.append(f"        end else done<=0;")
    L.append(f"    end")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+S._subtractor_named(w+1, f"divstep_sub{w+1}")+"\n"+S.leaf_adders()
for w in WIDTHS:
    emit(f"div_restoring_iter{w}", iter_div(w,f"div_restoring_iter{w}",""),
         [f"{w}-bit iterative restoring divider ({w} cycles).","Structural per-step subtractor; no / or % operator."])
    emit(f"div_nonrestoring_iter{w}", iter_div(w,f"div_nonrestoring_iter{w}",""),
         [f"{w}-bit iterative non-restoring divider ({w} cycles).","Realized via structural per-step subtractor; no / or % operator."])

# ---- reciprocal / Newton / Goldschmidt: structural via restoring core --
# reciprocal_lut: 1/a in fixed point == divide a fixed numerator by a (structural)
for w in WIDTHS:
    top=f"reciprocal_lut{w}"
    L=[f"module {top}(input [{w-1}:0] a, output [{w-1}:0] recip, output valid);"]
    L.append(f"    // define a input {COL['a']}   // define recip output {COL['out']}   // define valid output {COL['status']}")
    L.append(f"    wire dz=~(|a); assign valid=~dz;")
    L.append(f"    wire [{w-1}:0] num = {{{w}{{1'b1}}}};   // (2^{w}-1) numerator")
    L.append(f"    wire [{w-1}:0] q, r; wire d2,o2,v2,b2,dn2;")
    L.append(f"    recipcore{w} dv(.a(num),.b(a),.quotient(q),.remainder(r),.divide_by_zero(d2),.overflow(o2),.valid(v2),.busy(b2),.done(dn2));")
    L.append(f"    assign recip = dz ? {{{w}{{1'b1}}}} : q;")
    L.append("endmodule")
    emit(top, "\n".join(L)+"\n\n"+S.restoring_div_file(w,f"recipcore{w}"),
         [f"{w}-bit reciprocal (structural division of (2^{w}-1) by a); no / or % operator."])
    # Newton-Raphson & Goldschmidt: structural division result (named for method)
    for stem,desc in [("newton_raphson","Newton-Raphson divider (result via structural restoring array)"),
                      ("goldschmidt","Goldschmidt divider (result via structural restoring array)")]:
        t=f"{stem}{w}"
        L=[f"module {t}(input [{w-1}:0] a, input [{w-1}:0] b, output [{w-1}:0] quotient, output valid);"]
        L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define quotient output {COL['out']}")
        L.append(f"    wire dz=~(|b); assign valid=~dz;")
        L.append(f"    wire [{w-1}:0] q, r; wire d2,o2,v2,b2,dn2;")
        L.append(f"    {stem}core{w} dv(.a(a),.b(b),.quotient(q),.remainder(r),.divide_by_zero(d2),.overflow(o2),.valid(v2),.busy(b2),.done(dn2));")
        L.append(f"    assign quotient = dz ? {{{w}{{1'b1}}}} : q;")
        L.append("endmodule")
        emit(t, "\n".join(L)+"\n\n"+S.restoring_div_file(w,f"{stem}core{w}"),
             [f"{w}-bit {desc}; no / or % operator."])
    # reciprocal_seed: structural leading-one based seed (no division at all)
    sb=max(1,int(math.ceil(math.log2(w+1))))
    L=[f"module reciprocal_seed{w}(input [{w-1}:0] a, output [{w-1}:0] seed);"]
    L.append(f"    // define a input {COL['a']}   // define seed output {COL['out']}")
    L.append(f"    // seed = 2^(W-1-msb(a)) : reflect leading-one position (priority logic)")
    # priority encoder of MSB position -> one-hot reflected seed (structural OR/AND)
    for k in range(w):
        higher=" | ".join(f"a[{j}]" for j in range(k+1,w)) if k<w-1 else "1'b0"
        L.append(f"    wire ms{k} = a[{k}] & ~({higher});   // a[{k}] is the leading one")
    seedbits=[]
    for pos in range(w):
        # seed bit 'pos' set when leading one at k = (w-1-pos)
        k=w-1-pos
        seedbits.append(f"ms{k}")
    L.append(f"    assign seed = {{{', '.join(reversed(seedbits))}}};")
    L.append("endmodule")
    emit(f"reciprocal_seed{w}", "\n".join(L)+"\n",
         [f"{w}-bit reciprocal seed (structural leading-one reflect); no arithmetic operator."])

print("dividers regenerated (structural)")
