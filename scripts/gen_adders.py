import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS, m_half_adder, m_full_adder, m_pg_bit

OUT=os.path.join(os.path.dirname(__file__),"..","src","adders")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")

DEFINES=(f"    // define a input {COL['a']}   // define b input {COL['b']}\n"
         f"    // define cin input {COL['cin']}   // define sum output {COL['out']}   // define cout output {COL['flag']}\n")

# ---------- basic adder cells (each its own file) -----------------------
emit("half_adder", m_half_adder(), ["Half adder: sum=a^b, carry=a&b."])
emit("full_adder", m_full_adder()+"\n"+m_half_adder(), ["Full adder from two half adders + OR."])
emit("full_adder_pg",
     "module full_adder_pg(input a, input b, input cin, output sum, output cout, output p, output g);\n"
     "    assign p = a ^ b;\n    assign g = a & b;\n    assign sum = p ^ cin;\n    assign cout = g | (p & cin);\nendmodule\n",
     ["Full adder exposing propagate/generate."])
emit("carry_generate_cell","module carry_generate_cell(input a, input b, output g);\n    assign g = a & b;\nendmodule\n",["Carry generate g=a&b."])
emit("carry_propagate_cell","module carry_propagate_cell(input a, input b, output p);\n    assign p = a ^ b;\nendmodule\n",["Carry propagate p=a^b."])
emit("black_cell",
     "module black_cell(input gk, input pk, input gj, input pj, output g, output p);\n"
     "    // (g,p) o (gj,pj): g = gk | (pk & gj); p = pk & pj\n"
     "    assign g = gk | (pk & gj);\n    assign p = pk & pj;\nendmodule\n",
     ["Prefix 'black' cell (full carry-merge operator)."])
emit("gray_cell",
     "module gray_cell(input gk, input pk, input gj, output g);\n"
     "    assign g = gk | (pk & gj);\nendmodule\n",
     ["Prefix 'gray' cell (carry-only merge)."])
emit("compressor3to2",
     "module compressor3to2(input a, input b, input c, output sum, output carry);\n"
     "    assign sum   = a ^ b ^ c;\n    assign carry = (a & b) | (b & c) | (a & c);\nendmodule\n",
     ["3:2 compressor (full adder counting cell)."])
emit("compressor4to2",
     "module compressor4to2(input a, input b, input c, input d, input cin, output sum, output carry, output cout);\n"
     "    wire s0,c0;\n"
     "    assign s0   = a ^ b ^ c;\n    assign c0   = (a&b)|(b&c)|(a&c);\n"
     "    assign sum  = s0 ^ d ^ cin;\n    assign carry= (s0&d)|(d&cin)|(s0&cin);\n    assign cout = c0;\nendmodule\n",
     ["4:2 compressor."])
emit("compressor5to3",
     "module compressor5to3(input a, input b, input c, input d, input e, output [2:0] sum);\n"
     "    // counts number of 1s among 5 inputs (0..5) -> 3-bit\n"
     "    assign sum = a + b + c + d + e;\nendmodule\n",
     ["5:3 counter (popcount of 5 bits)."])

# ---------- ripple-carry: add_rc4..32, composed from narrower ------------
def rc4():
    s=("module add_rc4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);\n"
       +DEFINES+
       "    wire c0,c1,c2;\n"
       "    full_adder fa0(.a(a[0]),.b(b[0]),.cin(cin),.sum(sum[0]),.cout(c0));\n"
       "    full_adder fa1(.a(a[1]),.b(b[1]),.cin(c0), .sum(sum[1]),.cout(c1));\n"
       "    full_adder fa2(.a(a[2]),.b(b[2]),.cin(c1), .sum(sum[2]),.cout(c2));\n"
       "    full_adder fa3(.a(a[3]),.b(b[3]),.cin(c2), .sum(sum[3]),.cout(cout));\n"
       "endmodule\n")
    return s + "\n" + m_full_adder() + "\n" + m_half_adder()

def rc_wide(w):
    h=w//2
    s=(f"module add_rc{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);\n"
       +DEFINES+
       f"    wire cmid;\n"
       f"    add_rc{h} lo(.a(a[{h-1}:0]),    .b(b[{h-1}:0]),    .cin(cin),  .sum(sum[{h-1}:0]),    .cout(cmid));\n"
       f"    add_rc{h} hi(.a(a[{w-1}:{h}]),  .b(b[{w-1}:{h}]),  .cin(cmid), .sum(sum[{w-1}:{h}]),  .cout(cout));\n"
       f"endmodule\n")
    return s
# build embedded chain text for a given width
def rc_chain(w):
    # returns concatenation of all add_rcX modules from w down to 4, plus full/half adder
    parts=[]
    cur=w
    while cur>4:
        parts.append(rc_wide(cur)); cur//=2
    parts.append(rc4())  # includes full+half adder
    return "\n".join(parts)
emit("add_rc4", rc4(), ["4-bit ripple-carry adder (4x full_adder)."])
for w in (8,16,32):
    emit(f"add_rc{w}", rc_chain(w), [f"{w}-bit ripple-carry adder (two add_rc{w//2} chained on midpoint carry)."])

# ---------- CLA: add_cla4 (flat lookahead), wider from groups -----------
def cla4():
    s=("module add_cla4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);\n"
       +DEFINES+
       "    wire [3:0] p,g;\n"
       "    pg_bit pg0(.a(a[0]),.b(b[0]),.p(p[0]),.g(g[0]));\n"
       "    pg_bit pg1(.a(a[1]),.b(b[1]),.p(p[1]),.g(g[1]));\n"
       "    pg_bit pg2(.a(a[2]),.b(b[2]),.p(p[2]),.g(g[2]));\n"
       "    pg_bit pg3(.a(a[3]),.b(b[3]),.p(p[3]),.g(g[3]));\n"
       "    wire c0,c1,c2,c3; assign c0=cin;\n"
       "    assign c1 = g[0] | (p[0]&c0);\n"
       "    assign c2 = g[1] | (p[1]&g[0]) | (p[1]&p[0]&c0);\n"
       "    assign c3 = g[2] | (p[2]&g[1]) | (p[2]&p[1]&g[0]) | (p[2]&p[1]&p[0]&c0);\n"
       "    assign cout = g[3] | (p[3]&g[2]) | (p[3]&p[2]&g[1]) | (p[3]&p[2]&p[1]&g[0]) | (p[3]&p[2]&p[1]&p[0]&c0);\n"
       "    assign sum[0]=p[0]^c0; assign sum[1]=p[1]^c1; assign sum[2]=p[2]^c2; assign sum[3]=p[3]^c3;\n"
       "endmodule\n")
    return s + "\n" + m_pg_bit()

# CLA wider: build from two half-width CLA blocks that also expose group P/G.
# To keep it clean & self-contained while preserving hierarchy, we use an
# internal block 'cla4_blk' that outputs group P,G, and compose upward.
def cla_blk4():
    return ("module cla4_blk(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output gp, output gg);\n"
            "    wire [3:0] p,g;\n"
            "    pg_bit pg0(.a(a[0]),.b(b[0]),.p(p[0]),.g(g[0]));\n"
            "    pg_bit pg1(.a(a[1]),.b(b[1]),.p(p[1]),.g(g[1]));\n"
            "    pg_bit pg2(.a(a[2]),.b(b[2]),.p(p[2]),.g(g[2]));\n"
            "    pg_bit pg3(.a(a[3]),.b(b[3]),.p(p[3]),.g(g[3]));\n"
            "    wire c0,c1,c2,c3; assign c0=cin;\n"
            "    assign c1 = g[0] | (p[0]&c0);\n"
            "    assign c2 = g[1] | (p[1]&g[0]) | (p[1]&p[0]&c0);\n"
            "    assign c3 = g[2] | (p[2]&g[1]) | (p[2]&p[1]&g[0]) | (p[2]&p[1]&p[0]&c0);\n"
            "    assign sum[0]=p[0]^c0; assign sum[1]=p[1]^c1; assign sum[2]=p[2]^c2; assign sum[3]=p[3]^c3;\n"
            "    assign gp = &p;                       // group propagate\n"
            "    assign gg = g[3] | (p[3]&g[2]) | (p[3]&p[2]&g[1]) | (p[3]&p[2]&p[1]&g[0]);  // group generate\n"
            "endmodule\n")

def cla_wide(w):
    nblk=w//4
    lines=[f"module add_cla{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    lines.append(DEFINES.rstrip("\n"))
    lines.append(f"    wire [{nblk-1}:0] gp, gg;")
    lines.append(f"    wire [{nblk}:0] carry; assign carry[0]=cin;")
    for k in range(nblk):
        lo=k*4; hi=lo+3
        lines.append(f"    cla4_blk blk{k}(.a(a[{hi}:{lo}]), .b(b[{hi}:{lo}]), .cin(carry[{k}]), .sum(sum[{hi}:{lo}]), .gp(gp[{k}]), .gg(gg[{k}]));")
    # group-level lookahead carries between blocks
    for k in range(nblk):
        lines.append(f"    assign carry[{k+1}] = gg[{k}] | (gp[{k}] & carry[{k}]);")
    lines.append(f"    assign cout = carry[{nblk}];")
    lines.append("endmodule")
    return "\n".join(lines)+"\n\n"+cla_blk4()+"\n"+m_pg_bit()

emit("add_cla4", cla4(), ["4-bit carry-lookahead adder (flat lookahead carries)."])
for w in (8,16,32):
    emit(f"add_cla{w}", cla_wide(w), [f"{w}-bit CLA: {w//4} x cla4 blocks + group lookahead."])

print("adders (cells, rc, cla) generated")
