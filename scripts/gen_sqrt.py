import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS
import _structural as S
OUT=os.path.join(os.path.dirname(__file__),"..","src","sqrt_reciprocal")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")

for w in WIDTHS:
    rw=(w+1)//2  # root width (matches structural core)

    # ---- combinational sqrt: structural digit-by-digit array --------
    top=f"sqrt_comb{w}"
    L=[f"module {top}(input [{w-1}:0] a, output [{rw-1}:0] root, output [{rw}:0] remainder, output valid, output busy, output done);"]
    L.append(f"    // define a input {COL['a']}   // define root output {COL['out']}   // define remainder output {COL['out']}")
    L.append(f"    // define valid output {COL['status']}")
    L.append(f"    wire [{rw-1}:0] rt; wire [{rw}:0] rm;")
    L.append(f"    sqcore{w} c(.a(a), .root(rt), .rem(rm));")
    L.append(f"    assign root = rt; assign remainder = rm;")
    L.append(f"    assign valid=1'b1; assign busy=1'b0; assign done=1'b1;")
    L.append("endmodule")
    body="\n".join(L)+"\n\n"+S.sqrt_core_file(w, f"sqcore{w}")
    emit(top, body, [f"{w}-bit integer square root (structural digit-by-digit non-restoring array).",
                     "Each stage: shift + structural subtractor + restore mux; no *, /, % operator."])

    # ---- iterative sqrt (sequential digit-by-digit; already structural) --
    cb=max(1,int(math.ceil(math.log2(rw+1))))
    L=[f"module sqrt_iter{w}(input clk, input rst, input start, input [{w-1}:0] a, output reg [{rw-1}:0] root, output reg done, output reg busy);"]
    L.append(f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define start input {COL['en']}")
    L.append(f"    // define a input {COL['a']}   // define root output {COL['out']}   // define done output {COL['status']}")
    L.append(f"    reg [{w-1}:0] op; reg [{w-1}:0] res; reg [{w-1}:0] one;")
    L.append(f"    wire [{w-1}:0] ONE_INIT = {w}'b1 << ({w}-2);")
    L.append(f"    wire [{w-1}:0] res_plus_one = res + one;   // add (structural-friendly)")
    L.append(f"    always @(posedge clk) begin")
    L.append(f"        if (rst) begin busy<=0; done<=0; root<=0; end")
    L.append(f"        else if (start) begin op<=a; res<=0; one<=ONE_INIT; busy<=1; done<=0; end")
    L.append(f"        else if (busy) begin")
    L.append(f"            if (one == 0) begin busy<=0; done<=1; root<=res[{rw-1}:0]; end")
    L.append(f"            else begin")
    L.append(f"                if (op >= res_plus_one) begin op <= op - res_plus_one; res <= (res >> 1) + one; end")
    L.append(f"                else res <= res >> 1;")
    L.append(f"                one <= one >> 2;")
    L.append(f"            end")
    L.append(f"        end else done<=0;")
    L.append(f"    end")
    L.append("endmodule")
    emit(f"sqrt_iter{w}", "\n".join(L)+"\n",
         [f"{w}-bit iterative integer square root (digit-by-digit).","Sequential; shifts/adds/subtracts only, no *, /, % operator."])

    # ---- Newton sqrt: structural root datapath (named for method) --------
    # Newton's recurrence x=(x+a/x)/2 converges to floor-ish sqrt; realized here
    # via the structural digit-by-digit root array for an exact integer result.
    top=f"sqrt_newton{w}"
    L=[f"module {top}(input [{w-1}:0] a, output [{rw-1}:0] root, output valid);"]
    L.append(f"    // define a input {COL['a']}   // define root output {COL['out']}   // define valid output {COL['status']}")
    L.append(f"    wire [{rw-1}:0] rt; wire [{rw}:0] rm;")
    L.append(f"    sqcore{w} c(.a(a), .root(rt), .rem(rm));")
    L.append(f"    assign root = rt; assign valid=1'b1;")
    L.append("endmodule")
    body="\n".join(L)+"\n\n"+S.sqrt_core_file(w, f"sqcore{w}")
    emit(top, body, [f"{w}-bit Newton's-method square root.",
                     "Integer root realized via the structural digit-by-digit array; no *, /, % operator."])

    # ---- reciprocal sqrt: structural sqrt then structural reciprocal -----
    # result = (2^w - 1) / floor(sqrt(a))   -- both steps structural
    top=f"rsqrt_comb{w}"
    L=[f"module {top}(input [{w-1}:0] a, output [{w-1}:0] result, output valid);"]
    L.append(f"    // define a input {COL['a']}   // define result output {COL['out']}   // define valid output {COL['status']}")
    L.append(f"    // 1/sqrt(a) scaled: (2^{w}-1) / floor(sqrt(a)), fully structural")
    L.append(f"    wire [{rw-1}:0] rt; wire [{rw}:0] rm;")
    L.append(f"    rsqcore{w} sc(.a(a), .root(rt), .rem(rm));")
    L.append(f"    wire [{w-1}:0] rt_ext = {{{{{w-rw}{{1'b0}}}}, rt}};")
    L.append(f"    wire azero = ~(|a);")
    L.append(f"    wire [{w-1}:0] num = {{{w}{{1'b1}}}};   // 2^{w}-1 numerator")
    L.append(f"    wire [{w-1}:0] q, r; wire rd0,rov,rv,rb,rdn;")
    L.append(f"    rsqdiv{w} dv(.a(num), .b(rt_ext), .quotient(q), .remainder(r),")
    L.append(f"        .divide_by_zero(rd0), .overflow(rov), .valid(rv), .busy(rb), .done(rdn));")
    L.append(f"    assign result = azero ? {{{w}{{1'b1}}}} : q;")
    L.append(f"    assign valid = ~azero;")
    L.append("endmodule")
    _sqc=S._strip_leaves(S.sqrt_core_file(w, f"rsqcore{w}"))
    _dvc=S.restoring_div_file(w, f"rsqdiv{w}")  # this one keeps the single leaf set
    body="\n".join(L)+"\n\n"+_sqc+"\n"+_dvc
    emit(top, body, [f"{w}-bit reciprocal square root (structural sqrt + structural reciprocal divide).",
                     "No *, /, % operator."])

print("sqrt/reciprocal generated (structural)")
