import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS, m_full_adder, m_half_adder, m_full_subtractor, m_half_subtractor
OUT=os.path.join(os.path.dirname(__file__),"..","src","subtractors")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")
FA=m_full_adder()+"\n"+m_half_adder()
FS=m_full_subtractor()
SUBDEF=(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define bin input {COL['cin']}\n"
        f"    // define diff output {COL['out']}   // define bout output {COL['flag']}\n")

# ---- subtractor cells --------------------------------------------------
emit("half_subtractor", m_half_subtractor(), ["Half subtractor: diff=a^b, bout=~a&b."])
emit("full_subtractor", m_full_subtractor(), ["Full subtractor: diff=a^b^bin, borrow out."])
emit("borrow_generate_cell","module borrow_generate_cell(input a, input b, output bg);\n    assign bg = (~a) & b;\nendmodule\n",["Borrow generate bg = ~a & b."])
emit("borrow_propagate_cell","module borrow_propagate_cell(input a, input b, output bp);\n    assign bp = ~(a ^ b);\nendmodule\n",["Borrow propagate bp = ~(a^b)."])

# ---- sub_borrow_ripple: full_subtractor chain -------------------------
def sub_ripple(w):
    L=[f"module sub_borrow_ripple{w}(input [{w-1}:0] a, input [{w-1}:0] b, input bin, output [{w-1}:0] diff, output bout);"]
    L.append(SUBDEF.rstrip("\n"))
    L.append(f"    wire [{w}:0] bw; assign bw[0]=bin;")
    for i in range(w):
        L.append(f"    full_subtractor fs{i}(.a(a[{i}]),.b(b[{i}]),.bin(bw[{i}]),.diff(diff[{i}]),.bout(bw[{i+1}]));")
    L.append(f"    assign bout=bw[{w}];")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+FS
for w in WIDTHS:
    emit(f"sub_borrow_ripple{w}", sub_ripple(w), [f"{w}-bit borrow-ripple subtractor (full_subtractor chain)."])

# ---- sub_twos_add_rc: a - b = a + ~b + 1 using ripple adder -----------
def rc_block(w):
    L=[f"module add_rc_unit{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(f"    wire [{w}:0] c; assign c[0]=cin;")
    for i in range(w):
        L.append(f"    full_adder fa{i}(.a(a[{i}]),.b(b[{i}]),.cin(c[{i}]),.sum(sum[{i}]),.cout(c[{i+1}]));")
    L.append(f"    assign cout=c[{w}];")
    L.append("endmodule")
    return "\n".join(L)+"\n"
for w in WIDTHS:
    body=(f"module sub_twos_add_rc{w}(input [{w-1}:0] a, input [{w-1}:0] b, output [{w-1}:0] diff, output bout);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define diff output {COL['out']}   // define bout output {COL['flag']}\n"
          f"    wire cout;\n"
          f"    add_rc_unit{w} u(.a(a), .b(~b), .cin(1'b1), .sum(diff), .cout(cout));\n"
          f"    assign bout = ~cout;   // borrow = NOT carry-out\nendmodule\n\n"
          +rc_block(w)+"\n"+FA)
    emit(f"sub_twos_add_rc{w}", body, [f"{w}-bit subtractor via two's complement (a + ~b + 1) on ripple adder."])

# ---- sub_twos_add_cla: same but CLA core -----------------------------
def cla_core(w):
    # simple flat-ish CLA built from 4-bit blocks rippled (reuse known-good)
    nb=w//4
    blk=("module cla4u(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);\n"
         "    wire [3:0] p=a^b, g=a&b; wire c0,c1,c2,c3; assign c0=cin;\n"
         "    assign c1=g[0]|(p[0]&c0);\n"
         "    assign c2=g[1]|(p[1]&g[0])|(p[1]&p[0]&c0);\n"
         "    assign c3=g[2]|(p[2]&g[1])|(p[2]&p[1]&g[0])|(p[2]&p[1]&p[0]&c0);\n"
         "    assign cout=g[3]|(p[3]&g[2])|(p[3]&p[2]&g[1])|(p[3]&p[2]&p[1]&g[0])|(p[3]&p[2]&p[1]&p[0]&c0);\n"
         "    assign sum[0]=p[0]^c0;assign sum[1]=p[1]^c1;assign sum[2]=p[2]^c2;assign sum[3]=p[3]^c3;\nendmodule\n")
    if w==4:
        core=("module add_cla_unit4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);\n"
              "    cla4u b0(.a(a),.b(b),.cin(cin),.sum(sum),.cout(cout));\nendmodule\n")
        return core+"\n"+blk
    L=[f"module add_cla_unit{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(f"    wire [{nb}:0] c; assign c[0]=cin;")
    for k in range(nb):
        lo=k*4;hi=lo+3
        L.append(f"    cla4u blk{k}(.a(a[{hi}:{lo}]),.b(b[{hi}:{lo}]),.cin(c[{k}]),.sum(sum[{hi}:{lo}]),.cout(c[{k+1}]));")
    L.append(f"    assign cout=c[{nb}];")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+blk
for w in WIDTHS:
    body=(f"module sub_twos_add_cla{w}(input [{w-1}:0] a, input [{w-1}:0] b, output [{w-1}:0] diff, output bout);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define diff output {COL['out']}   // define bout output {COL['flag']}\n"
          f"    wire cout;\n"
          f"    add_cla_unit{w} u(.a(a), .b(~b), .cin(1'b1), .sum(diff), .cout(cout));\n"
          f"    assign bout = ~cout;\nendmodule\n\n"+cla_core(w))
    emit(f"sub_twos_add_cla{w}", body, [f"{w}-bit subtractor via two's complement on CLA core."])

# ---- sub_cskip / sub_cselect: two's complement on those adder cores ---
# For brevity & guaranteed correctness, implement as two's complement using a
# carry-skip / carry-select adder core (embedded). We reuse a ripple core but
# name it appropriately with skip/select carry logic at 4-bit block level.
def skip_core(w):
    nb=max(1,w//4)
    rcb=("module rc4u(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);\n"
         "    wire [4:0] c; assign c[0]=cin;\n"
         "    full_adder f0(.a(a[0]),.b(b[0]),.cin(c[0]),.sum(sum[0]),.cout(c[1]));\n"
         "    full_adder f1(.a(a[1]),.b(b[1]),.cin(c[1]),.sum(sum[1]),.cout(c[2]));\n"
         "    full_adder f2(.a(a[2]),.b(b[2]),.cin(c[2]),.sum(sum[2]),.cout(c[3]));\n"
         "    full_adder f3(.a(a[3]),.b(b[3]),.cin(c[3]),.sum(sum[3]),.cout(c[4]));\n"
         "    assign cout=c[4];\nendmodule\n")
    L=[f"module addskip_unit{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(f"    wire [{nb}:0] c; assign c[0]=cin;")
    for k in range(nb):
        lo=k*4;hi=lo+3
        L.append(f"    wire [3:0] pp{k}=a[{hi}:{lo}]^b[{hi}:{lo}]; wire bp{k}=&pp{k}; wire rc{k};")
        L.append(f"    rc4u u{k}(.a(a[{hi}:{lo}]),.b(b[{hi}:{lo}]),.cin(c[{k}]),.sum(sum[{hi}:{lo}]),.cout(rc{k}));")
        L.append(f"    assign c[{k+1}]=bp{k}?c[{k}]:rc{k};")
    L.append(f"    assign cout=c[{nb}];")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+rcb+"\n"+FA
for w in WIDTHS:
    body=(f"module sub_cskip{w}(input [{w-1}:0] a, input [{w-1}:0] b, output [{w-1}:0] diff, output bout);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define diff output {COL['out']}   // define bout output {COL['flag']}\n"
          f"    wire cout; addskip_unit{w} u(.a(a),.b(~b),.cin(1'b1),.sum(diff),.cout(cout));\n"
          f"    assign bout=~cout;\nendmodule\n\n"+skip_core(w))
    emit(f"sub_cskip{w}", body, [f"{w}-bit subtractor (two's complement on carry-skip adder)."])

def select_core(w):
    nb=max(1,w//4)
    rcb=("module rc4s(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);\n"
         "    wire [4:0] c; assign c[0]=cin;\n"
         "    full_adder f0(.a(a[0]),.b(b[0]),.cin(c[0]),.sum(sum[0]),.cout(c[1]));\n"
         "    full_adder f1(.a(a[1]),.b(b[1]),.cin(c[1]),.sum(sum[1]),.cout(c[2]));\n"
         "    full_adder f2(.a(a[2]),.b(b[2]),.cin(c[2]),.sum(sum[2]),.cout(c[3]));\n"
         "    full_adder f3(.a(a[3]),.b(b[3]),.cin(c[3]),.sum(sum[3]),.cout(c[4]));\n"
         "    assign cout=c[4];\nendmodule\n")
    L=[f"module addsel_unit{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(f"    wire [{nb}:0] c; assign c[0]=cin;")
    for k in range(nb):
        lo=k*4;hi=lo+3
        if k==0:
            L.append(f"    wire rc{k}; rc4s u{k}(.a(a[{hi}:{lo}]),.b(b[{hi}:{lo}]),.cin(c[{k}]),.sum(sum[{hi}:{lo}]),.cout(rc{k})); assign c[{k+1}]=rc{k};")
        else:
            L.append(f"    wire [3:0] s0{k},s1{k}; wire co0{k},co1{k};")
            L.append(f"    rc4s u{k}a(.a(a[{hi}:{lo}]),.b(b[{hi}:{lo}]),.cin(1'b0),.sum(s0{k}),.cout(co0{k}));")
            L.append(f"    rc4s u{k}b(.a(a[{hi}:{lo}]),.b(b[{hi}:{lo}]),.cin(1'b1),.sum(s1{k}),.cout(co1{k}));")
            L.append(f"    assign sum[{hi}:{lo}]=c[{k}]?s1{k}:s0{k}; assign c[{k+1}]=c[{k}]?co1{k}:co0{k};")
    L.append(f"    assign cout=c[{nb}];")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+rcb+"\n"+FA
for w in WIDTHS:
    body=(f"module sub_cselect{w}(input [{w-1}:0] a, input [{w-1}:0] b, output [{w-1}:0] diff, output bout);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define diff output {COL['out']}   // define bout output {COL['flag']}\n"
          f"    wire cout; addsel_unit{w} u(.a(a),.b(~b),.cin(1'b1),.sum(diff),.cout(cout));\n"
          f"    assign bout=~cout;\nendmodule\n\n"+select_core(w))
    emit(f"sub_cselect{w}", body, [f"{w}-bit subtractor (two's complement on carry-select adder)."])

# ---- sub_prefix_kogge_stone: two's complement on KS adder ------------
from _prefix import verify
def ks_core(w):
    ok,stages=verify("kogge_stone",w); assert ok
    BLACK=("module bcell(input gk,input pk,input gj,input pj,output g,output p);\n"
           "    assign g=gk|(pk&gj); assign p=pk&pj;\nendmodule\n")
    L=[f"module ks_unit{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(f"    wire [{w-1}:0] p0,g0;")
    for i in range(w):
        L.append(f"    assign p0[{i}]=a[{i}]^b[{i}]; assign g0[{i}]=a[{i}]&b[{i}];")
    pg,pp="g0","p0"
    for lvl,st in enumerate(stages):
        gn=f"g{lvl+1}";pn=f"p{lvl+1}"
        L.append(f"    wire [{w-1}:0] {gn},{pn};")
        for i in range(w):
            if i in st:
                hi,lo=st[i]
                L.append(f"    bcell c{lvl}_{i}(.gk({pg}[{hi}]),.pk({pp}[{hi}]),.gj({pg}[{lo}]),.pj({pp}[{lo}]),.g({gn}[{i}]),.p({pn}[{i}]));")
            else:
                L.append(f"    assign {gn}[{i}]={pg}[{i}]; assign {pn}[{i}]={pp}[{i}];")
        pg,pp=gn,pn
    L.append(f"    wire [{w}:0] c; assign c[0]=cin;")
    for i in range(w):
        L.append(f"    assign c[{i+1}]={pg}[{i}]|({pp}[{i}]&cin);")
    L.append(f"    assign cout=c[{w}];")
    for i in range(w):
        L.append(f"    assign sum[{i}]=p0[{i}]^c[{i}];")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+BLACK
for w in WIDTHS:
    body=(f"module sub_prefix_kogge_stone{w}(input [{w-1}:0] a, input [{w-1}:0] b, output [{w-1}:0] diff, output bout);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define diff output {COL['out']}   // define bout output {COL['flag']}\n"
          f"    wire cout; ks_unit{w} u(.a(a),.b(~b),.cin(1'b1),.sum(diff),.cout(cout));\n"
          f"    assign bout=~cout;\nendmodule\n\n"+ks_core(w))
    emit(f"sub_prefix_kogge_stone{w}", body, [f"{w}-bit subtractor (two's complement on Kogge-Stone prefix adder)."])

print("subtractors generated")
