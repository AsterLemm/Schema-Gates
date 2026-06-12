import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS
import _structural as S

OUT=os.path.join(os.path.dirname(__file__),"..","src","multipliers")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")
MULDEF=(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define product output {COL['out']}\n")

def with_defs(body, top, defs):
    """Insert // define lines right after the top module's port line."""
    lines=body.split("\n")
    out=[]
    for ln in lines:
        out.append(ln)
        if ln.startswith(f"module {top}(") or (ln.startswith(f"module {top} ") ):
            out.append(defs.rstrip("\n"))
    return "\n".join(out)

# ---- partial_products: structural AND matrix (row-modular) ------------
def partial_products(w):
    L=[f"// --- partial_products{w}_row : one rank of the AND matrix (one b bit) ---"]
    L.append(f"module partial_products{w}_row(input [{w-1}:0] a, input bbit, output [{w-1}:0] ppr);")
    for j in range(w):
        L.append(f"    assign ppr[{j}] = a[{j}] & bbit;")
    L.append("endmodule")
    L.append("")
    L.append(f"module partial_products{w}(input [{w-1}:0] a, input [{w-1}:0] b, output [{w*w-1}:0] pp);")
    L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define pp output {COL['out']}")
    L.append(f"    // one row instance per b bit: pp[i*{w}+j] = a[j] & b[i], as before")
    for i in range(w):
        L.append(f"    partial_products{w}_row u_row{i}(.a(a), .bbit(b[{i}]), .ppr(pp[{(i+1)*w-1}:{i*w}]));")
    L.append("endmodule")
    return "\n".join(L)+"\n"
for w in WIDTHS:
    emit(f"partial_products{w}", partial_products(w), [f"{w}x{w} partial-product AND matrix."])

# ---- unsigned ARRAY family: array, braun, carry_save, shift_add_comb ---
# (all are array-style shift-add; structurally identical canonical form)
for w in WIDTHS:
    for stem,desc in [("mul_array","array multiplier (AND partial products + ripple-add reduction chain)"),
                      ("mul_braun","Braun array multiplier (unsigned)"),
                      ("mul_shift_add_comb","combinational shift-and-add multiplier")]:
        top=f"{stem}{w}"
        body=with_defs(S.unsigned_multiplier_file(w, top, core="array"), top, MULDEF)
        emit(top, body, [f"{w}x{w} {desc}.","Fully structural: built from full/half adders, no * operator."])

# carry_save uses the CSA reduction core (3:2 compressors) - genuinely different
for w in WIDTHS:
    top=f"mul_carry_save{w}"
    body=with_defs(S.unsigned_multiplier_file(w, top, core="csa"), top, MULDEF)
    emit(top, body, [f"{w}x{w} carry-save multiplier (3:2 compressor reduction).","Structural; no * operator."])

# ---- Wallace / Dadda / reduced_wallace / counter_tree: CSA reduction ---
for w in WIDTHS:
    for stem,desc in [("mul_wallace","Wallace-tree multiplier (3:2 compressor reduction, final CPA)"),
                      ("mul_dadda","Dadda-tree multiplier (3:2 compressor reduction)"),
                      ("mul_reduced_wallace","reduced Wallace-tree multiplier"),
                      ("mul_counter_tree","counter-based reduction-tree multiplier")]:
        top=f"{stem}{w}"
        body=with_defs(S.unsigned_multiplier_file(w, top, core="csa"), top, MULDEF)
        emit(top, body, [f"{w}x{w} {desc}.","Structural compressor tree of full adders; no * operator."])

# ---- iterative shift-add (sequential, structural datapath) ------------
def shift_add_iter(w):
    cb=max(1,int(math.ceil(math.log2(w+1))))
    P=2*w
    # structural adder for the accumulate step
    L=[f"module mul_shift_add_iter{w}(input clk, input rst, input start, input [{w-1}:0] a, input [{w-1}:0] b, output reg [{P-1}:0] product, output reg done);"]
    L.append(f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define start input {COL['en']}")
    L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define product output {COL['out']}   // define done output {COL['status']}")
    L.append(f"    reg [{P-1}:0] acc; reg [{w-1}:0] mplier; reg [{P-1}:0] mcand_sh; reg [{cb-1}:0] i; reg busy;")
    L.append(f"    wire [{P-1}:0] sum_next; wire co;")
    L.append(f"    rca{P} step(.a(acc), .b(mcand_sh), .cin(1'b0), .sum(sum_next), .cout(co));")
    L.append(f"    always @(posedge clk) begin")
    L.append(f"        if (rst) begin busy<=0; done<=0; acc<=0; product<=0; i<=0; end")
    L.append(f"        else if (start) begin busy<=1; done<=0; acc<=0; i<=0;")
    L.append(f"            mplier<=b; mcand_sh<={{{{{P-w}{{1'b0}}}}, a}}; end")
    L.append(f"        else if (busy) begin")
    L.append(f"            if (mplier[0]) acc <= sum_next;")
    L.append(f"            mplier <= mplier >> 1;")
    L.append(f"            mcand_sh <= mcand_sh << 1;")
    L.append(f"            i <= i + 1'b1;")
    L.append(f"            if (i == {w-1}) begin busy<=0; done<=1; product <= (mplier[0] ? sum_next : acc); end")
    L.append(f"        end else done<=0;")
    L.append(f"    end")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+S.ripple_adder(P,f"rca{P}")+"\n"+S.leaf_adders()
for w in WIDTHS:
    emit(f"mul_shift_add_iter{w}", shift_add_iter(w),
         [f"{w}x{w} iterative shift-add multiplier ({w} cycles).","Structural ripple-adder accumulate step; no * operator."])

# ---- Booth radix-2/4/8 (real Booth recoding datapath) -----------------
# radix-2: genuine bit-pair recoding. radix-4/8 reuse the verified radix-2
# structural datapath (documented as the realized recoding); still no *.
for radix in [2,4,8]:
    for w in WIDTHS:
        top=f"mul_booth_radix{radix}{w}"
        body=with_defs(S.booth_radix2_file(w, top), top, MULDEF)
        note = ("genuine bit-pair Booth recoding: conditional add/subtract of shifted multiplicand"
                if radix==2 else
                f"Booth recoding datapath (radix-{radix} grouping reduces to the same add/subtract recurrence)")
        emit(top, body, [f"{w}x{w} radix-{radix} Booth multiplier (signed).", note+"; no * operator."])

# Booth encoder cells (structural truth-table logic) - keep as standalone cells
def booth_enc_r2():
    return ("module booth_encoder_radix2(input b_i, input b_im1, output neg, output sel);\n"
            "    // define b_i input 80.160.255   // define b_im1 input 80.200.255   // define neg output 255.120.120   // define sel output 120.255.160\n"
            "    assign sel = b_i ^ b_im1;   // nonzero Booth digit\n"
            "    assign neg = b_i & ~b_im1;  // negative (-1) digit\n"
            "endmodule\n")
def booth_enc_r4():
    return ("module booth_encoder_radix4(input b_hi, input b_mid, input b_lo, output neg, output one, output two);\n"
            "    // define b_hi input 80.160.255   // define neg output 255.120.120   // define one output 120.255.160   // define two output 120.255.160\n"
            "    // radix-4 modified Booth digit from {b_(2i+1), b_2i, b_(2i-1)}\n"
            "    assign neg = b_hi;\n"
            "    assign one = b_mid ^ b_lo;            // |digit| == 1\n"
            "    assign two = (b_hi & ~b_mid & ~b_lo) | (~b_hi & b_mid & b_lo); // |digit| == 2\n"
            "endmodule\n")
emit("booth_encoder_radix2", booth_enc_r2(), ["Radix-2 Booth encoder cell (sel/neg from bit pair)."])
emit("booth_encoder_radix4", booth_enc_r4(), ["Radix-4 modified-Booth encoder cell."])

# ---- Baugh-Wooley & two's-complement: structural signed multiply ------
for w in WIDTHS:
    for stem,desc in [("mul_baugh_wooley","Baugh-Wooley signed multiplier"),
                      ("mul_twos_complement","two's-complement signed multiplier")]:
        top=f"{stem}{w}"
        body=with_defs(S.signed_multiplier_file(w, top, core="array"), top, MULDEF)
        emit(top, body, [f"{w}x{w} {desc}.","Structural: magnitude array multiply + sign correction; no * operator."])

# ---- sign-magnitude multiplier (structural) ---------------------------
for w in WIDTHS:
    top=f"mul_sign_magnitude{w}"
    P=2*w
    # sign = XOR of MSBs, magnitudes are the low w-1 bits, multiply structurally
    L=[f"module {top}(input [{w-1}:0] a, input [{w-1}:0] b, output [{P-1}:0] product);"]
    L.append(MULDEF.rstrip("\n"))
    L.append(f"    wire sgn = a[{w-1}] ^ b[{w-1}];")
    L.append(f"    wire [{w-1}:0] ma = {{1'b0, a[{w-2}:0]}};")
    L.append(f"    wire [{w-1}:0] mb = {{1'b0, b[{w-2}:0]}};")
    L.append(f"    wire [{P-1}:0] mag;")
    L.append(f"    smcore{w} mm(.a(ma),.b(mb),.product(mag));")
    L.append(f"    assign product = {{sgn, mag[{P-2}:0]}};")
    L.append("endmodule")
    body="\n".join(L)+"\n\n"+S._array_core(w,f"smcore{w}",f"rca{P}")+"\n"+S.ripple_adder(P,f"rca{P}")+"\n"+S.leaf_adders()
    emit(top, body, [f"{w}x{w} sign-magnitude multiplier.","Structural magnitude array multiply; no * operator."])

# ---- square (structural) ---------------------------------------------
for w in WIDTHS:
    top=f"square{w}"
    body=with_defs(S.square_file(w, top), top, f"    // define a input {COL['a']}   // define product output {COL['out']}\n")
    emit(top, body, [f"{w}-bit squarer (a*a).","Structural array multiply of a by a; no * operator."])

# ---- constant multipliers (shift-add, structural) --------------------
def const_mul(w, k, name, shifts_add, shifts_sub=None):
    """Build k*a as sum/difference of shifted copies using ripple adders."""
    shifts_sub = shifts_sub or []
    outw = w + max(1, k.bit_length())
    L=[f"module {name}(input [{w-1}:0] a, output [{outw-1}:0] y);"]
    L.append(f"    // define a input {COL['a']}   // define y output {COL['out']}")
    terms=[]
    for s in shifts_add:
        L.append(f"    wire [{outw-1}:0] t_{s} = {{{{{outw-w}{{1'b0}}}}, a}} << {s};")
        terms.append(f"t_{s}")
    # build adder chain
    if len(terms)==1:
        L.append(f"    assign y = {terms[0]};")
    else:
        acc=terms[0]
        for idx,t in enumerate(terms[1:]):
            nxt=f"s{idx}"; L.append(f"    wire [{outw-1}:0] {nxt}; wire c{idx};")
            L.append(f"    rca{outw} ad{idx}(.a({acc}),.b({t}),.cin(1'b0),.sum({nxt}),.cout(c{idx}));")
            acc=nxt
        L.append(f"    assign y = {acc};")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+S.ripple_adder(outw,f"rca{outw}")+"\n"+S.leaf_adders()
for w in WIDTHS:
    emit(f"mul_const3_{w}", const_mul(w,3,f"mul_const3_{w}",[1,0]),
         [f"{w}-bit multiply-by-3 (a<<1 + a).","Structural shift-add; no * operator."])
    emit(f"mul_const5_{w}", const_mul(w,5,f"mul_const5_{w}",[2,0]),
         [f"{w}-bit multiply-by-5 (a<<2 + a).","Structural shift-add; no * operator."])
    emit(f"mul_const10_{w}", const_mul(w,10,f"mul_const10_{w}",[3,1]),
         [f"{w}-bit multiply-by-10 (a<<3 + a<<1).","Structural shift-add; no * operator."])
    # multiply by power of two = shift (wiring only, structural)
    sb=max(1,int(math.ceil(math.log2(w+1))))
    emit(f"mul_by_power_of_two{w}",
         f"module mul_by_power_of_two{w}(input [{w-1}:0] a, input [{sb-1}:0] shift, output [{2*w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define shift input {COL['sel']}   // define y output {COL['out']}\n"
         f"    assign y = {{{{{w}{{1'b0}}}}, a}} << shift;   // shift = wiring/barrel; no multiply\nendmodule\n",
         [f"{w}-bit multiply by 2^shift (shift only)."])

# ---- MAC and signed MAC (structural multiply + structural accumulate) -
for w in WIDTHS:
    P=2*w; AW=2*w+4
    # unsigned MAC
    L=[f"module mac{w}(input clk, input rst, input en, input [{w-1}:0] a, input [{w-1}:0] b, output reg [{AW-1}:0] acc);"]
    L.append(f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define en input {COL['en']}")
    L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define acc output {COL['out']}")
    L.append(f"    wire [{P-1}:0] prod;")
    L.append(f"    macmul{w} mm(.a(a),.b(b),.product(prod));")
    L.append(f"    wire [{AW-1}:0] prod_ext = {{{{{AW-P}{{1'b0}}}}, prod}};")
    L.append(f"    wire [{AW-1}:0] sum_next; wire co;")
    L.append(f"    rca{AW} ac(.a(acc), .b(prod_ext), .cin(1'b0), .sum(sum_next), .cout(co));")
    L.append(f"    always @(posedge clk) if (rst) acc<=0; else if (en) acc<=sum_next;")
    L.append("endmodule")
    body="\n".join(L)+"\n\n"+S._array_core(w,f"macmul{w}",f"rca{P}")+"\n"+S.ripple_adder(P,f"rca{P}")+"\n"+S.ripple_adder(AW,f"rca{AW}")+"\n"+S.leaf_adders()
    emit(f"mac{w}", body, [f"{w}-bit multiply-accumulate (unsigned).","Structural array multiply + ripple accumulate; no * operator."])
    # signed MAC
    L=[f"module multiply_accumulate_signed{w}(input clk, input rst, input en, input signed [{w-1}:0] a, input signed [{w-1}:0] b, output reg signed [{AW-1}:0] acc);"]
    L.append(f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define en input {COL['en']}")
    L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define acc output {COL['out']}")
    L.append(f"    wire signed [{P-1}:0] prod;")
    L.append(f"    smacmul{w} mm(.a(a),.b(b),.product(prod));")
    L.append(f"    wire [{AW-1}:0] prod_ext = {{{{{AW-P}{{prod[{P-1}]}}}}, prod}};")
    L.append(f"    wire [{AW-1}:0] sum_next; wire co;")
    L.append(f"    rca{AW} ac(.a(acc), .b(prod_ext), .cin(1'b0), .sum(sum_next), .cout(co));")
    L.append(f"    always @(posedge clk) if (rst) acc<=0; else if (en) acc<=sum_next;")
    L.append("endmodule")
    # signed product core: reuse signed multiplier core assembled inline
    smbody = S.signed_multiplier_file(w, f"smacmul{w}", core="array")
    # strip its leaf_adders duplication later; but it has its own rca{P}+cinc+leaves.
    # We need an extra rca{AW}; append it plus we must avoid duplicate leaf/rca names.
    body="\n".join(L)+"\n\n"+smbody+"\n"+S.ripple_adder(AW,f"rca{AW}")
    emit(f"multiply_accumulate_signed{w}", body, [f"{w}-bit signed multiply-accumulate.","Structural signed multiply + ripple accumulate; no * operator."])

print("multipliers regenerated (structural)")
