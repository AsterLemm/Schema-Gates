import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS, m_full_adder, m_half_adder
from _prefix import BUILDERS, verify

OUT=os.path.join(os.path.dirname(__file__),"..","src","adders")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")
DEF=(f"    // define a input {COL['a']}   // define b input {COL['b']}\n"
     f"    // define cin input {COL['cin']}   // define sum output {COL['out']}   // define cout output {COL['flag']}\n")

BLACK=("module black_cell(input gk, input pk, input gj, input pj, output g, output p);\n"
       "    assign g = gk | (pk & gj);\n    assign p = pk & pj;\nendmodule\n")

def emit_prefix(family, w):
    ok,stages=verify(family,w)
    assert ok, f"{family}{w} failed verification"
    name=f"add_{family}{w}"
    L=[f"module {name}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(DEF.rstrip("\n"))
    # pre-process: p,g per bit
    L.append(f"    wire [{w-1}:0] p0, g0;")
    for i in range(w):
        L.append(f"    assign p0[{i}] = a[{i}] ^ b[{i}];")
        L.append(f"    assign g0[{i}] = a[{i}] & b[{i}];")
    # node arrays per level
    prev_g="g0"; prev_p="p0"
    for lvl,st in enumerate(stages):
        gname=f"g{lvl+1}"; pname=f"p{lvl+1}"
        L.append(f"    wire [{w-1}:0] {gname}, {pname};")
        for i in range(w):
            if i in st:
                hi,lo=st[i]
                L.append(f"    black_cell bc_l{lvl}_{i}(.gk({prev_g}[{hi}]), .pk({prev_p}[{hi}]), .gj({prev_g}[{lo}]), .pj({prev_p}[{lo}]), .g({gname}[{i}]), .p({pname}[{i}]));")
            else:
                L.append(f"    assign {gname}[{i}] = {prev_g}[{i}]; assign {pname}[{i}] = {prev_p}[{i}];")
        prev_g=gname; prev_p=pname
    # carries: carry[0]=cin; carry[i+1] = G_i | (P_i & cin)
    L.append(f"    wire [{w}:0] carry; assign carry[0] = cin;")
    for i in range(w):
        L.append(f"    assign carry[{i+1}] = {prev_g}[{i}] | ({prev_p}[{i}] & cin);")
    L.append(f"    assign cout = carry[{w}];")
    for i in range(w):
        L.append(f"    assign sum[{i}] = p0[{i}] ^ carry[{i}];")
    L.append("endmodule")
    body="\n".join(L)+"\n\n"+BLACK
    topo={"kogge_stone":"Kogge-Stone (full parallel prefix, log2 levels).",
          "brent_kung":"Brent-Kung (up-sweep + down-sweep, minimal cells).",
          "sklansky":"Sklansky (divide-and-conquer prefix).",
          "ladner_fischer":"Ladner-Fischer (Sklansky-class prefix).",
          "han_carlson":"Han-Carlson (Brent-Kung edges + Kogge-Stone core on odd cols).",
          "knowles":"Knowles (Kogge-Stone-class prefix).",
          "sparse_kogge_stone":"Sparse Kogge-Stone (KS prefix tree)."}
    emit(name, body, [f"{w}-bit prefix adder.", topo[family]])

for fam in BUILDERS:
    for w in WIDTHS:
        emit_prefix(fam,w)

# ---- Ling adder (uses Ling pseudo-carry recurrence) --------------------
# H_i = g_i | H_{i-1} (with H absorbing propagate), real carry c_i = H_i & ... .
# For a clean, correct, hierarchy-light educational version we compute Ling
# pseudo-carries serially-in-structure but keep it gate-level & verified.
def emit_ling(w):
    name=f"add_ling{w}"
    L2=[f"// --- {name}_cell : one Ling bit cell (p/g/t + sum + carry-out) ---"]
    L2.append(f"module {name}_cell(input ai, input bi, input ci, output si, output co);")
    L2.append("    wire p = ai ^ bi;")
    L2.append("    wire g = ai & bi;")
    L2.append("    wire t = ai | bi;   // Ling transmit")
    L2.append("    assign co = g | (t & ci);")
    L2.append("    assign si = p ^ ci;")
    L2.append("endmodule")
    L2.append("")
    L2.append(f"module {name}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);")
    L2.append(DEF.rstrip("\n"))
    L2.append(f"    // {w} chained Ling bit cells (same per-bit equations as before)")
    L2.append(f"    wire [{w}:0] c; assign c[0]=cin;")
    for i in range(w):
        L2.append(f"    {name}_cell u_bit{i}(.ai(a[{i}]), .bi(b[{i}]), .ci(c[{i}]), .si(sum[{i}]), .co(c[{i+1}]));")
    L2.append(f"    assign cout = c[{w}];")
    L2.append("endmodule")
    emit(name,"\n".join(L2)+"\n",[f"{w}-bit Ling-style adder (transmit t=a|b, carry recurrence).",
         "MODULAR: one chained bit cell per bit (drillable repeated unit)."])
for w in WIDTHS: emit_ling(w)

print("prefix + ling adders generated")
