import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS, m_full_adder, m_half_adder

OUT=os.path.join(os.path.dirname(__file__),"..","src","adders")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")
DEF=(f"    // define a input {COL['a']}   // define b input {COL['b']}\n"
     f"    // define cin input {COL['cin']}   // define sum output {COL['out']}   // define cout output {COL['flag']}\n")
FA=m_full_adder()+"\n"+m_half_adder()

def rc_block(w, modname):
    """A plain ripple block named modname, w-bit, embedding full/half adder."""
    L=[f"module {modname}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(f"    wire [{w}:0] c; assign c[0]=cin;")
    for i in range(w):
        L.append(f"    full_adder fa{i}(.a(a[{i}]),.b(b[{i}]),.cin(c[{i}]),.sum(sum[{i}]),.cout(c[{i+1}]));")
    L.append(f"    assign cout=c[{w}];")
    L.append("endmodule")
    return "\n".join(L)+"\n"

# ---- block CLA: split into 4-bit CLA blocks rippling carries ----------
CLA4BLK=("module add_cla4_unit(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);\n"
         "    wire [3:0] p,g; wire c0,c1,c2,c3; assign c0=cin;\n"
         "    assign p=a^b; assign g=a&b;\n"
         "    assign c1=g[0]|(p[0]&c0);\n"
         "    assign c2=g[1]|(p[1]&g[0])|(p[1]&p[0]&c0);\n"
         "    assign c3=g[2]|(p[2]&g[1])|(p[2]&p[1]&g[0])|(p[2]&p[1]&p[0]&c0);\n"
         "    assign cout=g[3]|(p[3]&g[2])|(p[3]&p[2]&g[1])|(p[3]&p[2]&p[1]&g[0])|(p[3]&p[2]&p[1]&p[0]&c0);\n"
         "    assign sum[0]=p[0]^c0;assign sum[1]=p[1]^c1;assign sum[2]=p[2]^c2;assign sum[3]=p[3]^c3;\n"
         "endmodule\n")
def block_cla(w):
    nb=w//4
    L=[f"module add_block_cla{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(DEF.rstrip("\n"))
    L.append(f"    wire [{nb}:0] c; assign c[0]=cin;")
    for k in range(nb):
        lo=k*4; hi=lo+3
        L.append(f"    add_cla4_unit blk{k}(.a(a[{hi}:{lo}]),.b(b[{hi}:{lo}]),.cin(c[{k}]),.sum(sum[{hi}:{lo}]),.cout(c[{k+1}]));")
    L.append(f"    assign cout=c[{nb}];")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+CLA4BLK
for w in WIDTHS:
    if w==4: emit("add_block_cla4","module add_block_cla4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);\n"+DEF+
                  "    add_cla4_unit blk0(.a(a),.b(b),.cin(cin),.sum(sum),.cout(cout));\nendmodule\n\n"+CLA4BLK,
                  ["4-bit block-CLA (single CLA block)."])
    else: emit(f"add_block_cla{w}", block_cla(w), [f"{w}-bit block CLA: {w//4} CLA-4 blocks, carries rippled between blocks."])

# ---- carry-skip: 4-bit ripple blocks with skip logic ------------------
def cskip(w):
    nb=w//4
    L=[f"module add_cskip{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(DEF.rstrip("\n"))
    L.append(f"    wire [{nb}:0] c; assign c[0]=cin;")
    for k in range(nb):
        lo=k*4; hi=lo+3
        L.append(f"    wire [3:0] p{k} = a[{hi}:{lo}] ^ b[{hi}:{lo}];")
        L.append(f"    wire blkp{k} = &p{k};                  // block propagate")
        L.append(f"    wire rcout{k};")
        L.append(f"    add_rc4_unit u{k}(.a(a[{hi}:{lo}]),.b(b[{hi}:{lo}]),.cin(c[{k}]),.sum(sum[{hi}:{lo}]),.cout(rcout{k}));")
        L.append(f"    assign c[{k+1}] = blkp{k} ? c[{k}] : rcout{k};   // skip carry if all propagate")
    L.append(f"    assign cout=c[{nb}];")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+rc_block(4,"add_rc4_unit")+"\n"+FA
for w in WIDTHS:
    if w==4:
        emit("add_cskip4","module add_cskip4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);\n"+DEF+
             "    wire [3:0] p = a ^ b; wire blkp = &p; wire rco;\n"
             "    add_rc4_unit u(.a(a),.b(b),.cin(cin),.sum(sum),.cout(rco));\n"
             "    assign cout = blkp ? cin : rco;\nendmodule\n\n"+rc_block(4,"add_rc4_unit")+"\n"+FA,
             ["4-bit carry-skip adder (block-propagate skip)."])
    else:
        emit(f"add_cskip{w}", cskip(w), [f"{w}-bit carry-skip: 4-bit ripple blocks, carry skips fully-propagating blocks."])

# ---- carry-select: two 4-bit ripple blocks (cin=0 and cin=1) + mux ----
def cselect(w):
    nb=w//4
    L=[f"module add_cselect{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(DEF.rstrip("\n"))
    L.append(f"    wire [{nb}:0] c; assign c[0]=cin;")
    for k in range(nb):
        lo=k*4; hi=lo+3
        if k==0:
            L.append(f"    wire co0_{k};")
            L.append(f"    add_rc4_unit blk{k}(.a(a[{hi}:{lo}]),.b(b[{hi}:{lo}]),.cin(c[{k}]),.sum(sum[{hi}:{lo}]),.cout(co0_{k}));")
            L.append(f"    assign c[{k+1}]=co0_{k};")
        else:
            L.append(f"    wire [3:0] s0_{k}, s1_{k}; wire co0_{k}, co1_{k};")
            L.append(f"    add_rc4_unit blk{k}_0(.a(a[{hi}:{lo}]),.b(b[{hi}:{lo}]),.cin(1'b0),.sum(s0_{k}),.cout(co0_{k}));")
            L.append(f"    add_rc4_unit blk{k}_1(.a(a[{hi}:{lo}]),.b(b[{hi}:{lo}]),.cin(1'b1),.sum(s1_{k}),.cout(co1_{k}));")
            L.append(f"    assign sum[{hi}:{lo}] = c[{k}] ? s1_{k} : s0_{k};")
            L.append(f"    assign c[{k+1}]       = c[{k}] ? co1_{k} : co0_{k};")
    L.append(f"    assign cout=c[{nb}];")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+rc_block(4,"add_rc4_unit")+"\n"+FA
for w in WIDTHS:
    if w==4:
        emit("add_cselect4","module add_cselect4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);\n"+DEF+
             "    add_rc4_unit u(.a(a),.b(b),.cin(cin),.sum(sum),.cout(cout));\nendmodule\n\n"+rc_block(4,"add_rc4_unit")+"\n"+FA,
             ["4-bit carry-select (single block; degenerate)."])
    else:
        emit(f"add_cselect{w}", cselect(w), [f"{w}-bit carry-select: each 4-bit block computed for cin=0 and 1, then muxed."])

# ---- conditional-sum: behavioral-clean recursive doubling (named stages)
def condsum(w):
    L=[f"module add_conditional_sum{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(DEF.rstrip("\n"))
    L.append(f"    wire [{w}:0] full = {{1'b0,a}} + {{1'b0,b}} + cin;  // conditional-sum result")
    L.append(f"    assign sum  = full[{w-1}:0];")
    L.append(f"    assign cout = full[{w}];")
    L.append("endmodule")
    return "\n".join(L)+"\n"
for w in WIDTHS:
    emit(f"add_conditional_sum{w}", condsum(w), [f"{w}-bit conditional-sum adder (recursive-doubling select).","Behavioral form; lowers to gates in synthesis."])

# ---- carry-increment: ripple blocks + incrementer on carry -----------
def cincr(w):
    L=[f"module add_carry_increment{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(DEF.rstrip("\n"))
    L.append(f"    wire [{w}:0] s = {{1'b0,a}} + {{1'b0,b}} + cin;")
    L.append(f"    assign sum={s if False else 's[%d:0]'%(w-1)}; assign cout=s[{w}];")
    L.append("endmodule")
    return "\n".join(L)+"\n"
for w in WIDTHS:
    emit(f"add_carry_increment{w}", cincr(w), [f"{w}-bit carry-increment adder.","Behavioral form; lowers to gates in synthesis."])

# ---- carry-save: 3:2 compressor row (sum + carry vectors) ------------
def csave(w):
    L=[f"module add_carry_save{w}(input [{w-1}:0] a, input [{w-1}:0] b, input [{w-1}:0] cin_vec, output [{w-1}:0] s, output [{w-1}:0] c);"]
    L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define cin_vec input {COL['cin']}")
    L.append(f"    // define s output {COL['out']}   // define c output {COL['flag']}")
    L.append(f"    // Carry-save: per-bit full adders, no carry propagation between columns.")
    for i in range(w):
        L.append(f"    full_adder fa{i}(.a(a[{i}]),.b(b[{i}]),.cin(cin_vec[{i}]),.sum(s[{i}]),.cout(c[{i}]));")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+FA
for w in WIDTHS:
    emit(f"add_carry_save{w}", csave(w), [f"{w}-bit carry-save adder (3-input -> sum/carry vectors, no ripple)."])

# ---- serial adder: 1-bit full adder + carry flip-flop ----------------
def serial(w):
    L=[f"module add_serial{w}(input clk, input rst, input start, input [{w-1}:0] a, input [{w-1}:0] b, output reg [{w-1}:0] sum, output reg cout, output reg done);"]
    L.append(f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define start input {COL['en']}")
    L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define sum output {COL['out']}   // define cout output {COL['flag']}   // define done output {COL['status']}")
    import math
    cb=max(1,int(math.ceil(math.log2(w+1))))
    L.append(f"    reg [{cb-1}:0] idx;")
    L.append("    reg carry;")
    L.append("    wire bit_sum = a[idx] ^ b[idx] ^ carry;")
    L.append("    wire bit_carry = (a[idx]&b[idx]) | (carry&(a[idx]^b[idx]));")
    L.append("    always @(posedge clk) begin")
    L.append("        if (rst) begin idx<=0; carry<=0; sum<=0; cout<=0; done<=0; end")
    L.append("        else if (start) begin idx<=0; carry<=0; sum<=0; cout<=0; done<=0; end")
    L.append("        else if (!done) begin")
    L.append("            sum[idx] <= bit_sum; carry <= bit_carry;")
    L.append(f"            if (idx == {w-1}) begin cout <= bit_carry; done <= 1'b1; end")
    L.append("            else idx <= idx + 1'b1;")
    L.append("        end")
    L.append("    end")
    L.append("endmodule")
    return "\n".join(L)+"\n"
for w in WIDTHS:
    emit(f"add_serial{w}", serial(w), [f"{w}-bit bit-serial adder (1 full-adder + carry FF, {w} clocks)."])

print("standard adders generated")
