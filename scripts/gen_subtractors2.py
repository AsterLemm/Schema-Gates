import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS, m_full_adder, m_half_adder
from _prefix import verify
OUT=os.path.join(os.path.dirname(__file__),"..","src","subtractors")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")
FA=m_full_adder()+"\n"+m_half_adder()

ASDEF=(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define sub input {COL['sel']}\n"
       f"    // define result output {COL['out']}   // define cout output {COL['flag']}   // define ovf output {COL['status']}\n")

def rc_unit(w):
    L=[f"module rcadd{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(f"    wire [{w}:0] c; assign c[0]=cin;")
    for i in range(w):
        L.append(f"    full_adder fa{i}(.a(a[{i}]),.b(b[{i}]),.cin(c[{i}]),.sum(sum[{i}]),.cout(c[{i+1}]));")
    L.append(f"    assign cout=c[{w}];")
    L.append("endmodule")
    return "\n".join(L)+"\n"

# addsub_rc: result = sub ? a-b : a+b ; b^{sub}, cin=sub
for w in WIDTHS:
    m1=w-1
    body=(f"module addsub_rc{w}(input [{m1}:0] a, input [{m1}:0] b, input sub, output [{m1}:0] result, output cout, output ovf);\n"
          +ASDEF+
          f"    wire [{m1}:0] bx = b ^ {{{w}{{sub}}}};\n"
          f"    wire co;\n"
          f"    rcadd{w} u(.a(a), .b(bx), .cin(sub), .sum(result), .cout(co));\n"
          f"    assign cout = co;\n"
          f"    assign ovf  = (a[{m1}]==bx[{m1}]) & (result[{m1}]!=a[{m1}]);\nendmodule\n\n"+rc_unit(w)+"\n"+FA)
    emit(f"addsub_rc{w}", body, [f"{w}-bit add/sub on ripple adder (sub=1 -> a-b via b^1,cin=1)."])

# addsub_cla on CLA core
def cla_unit(w):
    blk=("module cla4z(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);\n"
         "    wire [3:0] p=a^b, g=a&b; wire c0,c1,c2,c3; assign c0=cin;\n"
         "    assign c1=g[0]|(p[0]&c0);assign c2=g[1]|(p[1]&g[0])|(p[1]&p[0]&c0);\n"
         "    assign c3=g[2]|(p[2]&g[1])|(p[2]&p[1]&g[0])|(p[2]&p[1]&p[0]&c0);\n"
         "    assign cout=g[3]|(p[3]&g[2])|(p[3]&p[2]&g[1])|(p[3]&p[2]&p[1]&g[0])|(p[3]&p[2]&p[1]&p[0]&c0);\n"
         "    assign sum[0]=p[0]^c0;assign sum[1]=p[1]^c1;assign sum[2]=p[2]^c2;assign sum[3]=p[3]^c3;\nendmodule\n")
    nb=max(1,w//4)
    L=[f"module claadd{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(f"    wire [{nb}:0] c; assign c[0]=cin;")
    for k in range(nb):
        lo=k*4;hi=lo+3
        L.append(f"    cla4z blk{k}(.a(a[{hi}:{lo}]),.b(b[{hi}:{lo}]),.cin(c[{k}]),.sum(sum[{hi}:{lo}]),.cout(c[{k+1}]));")
    L.append(f"    assign cout=c[{nb}];")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+blk
for w in WIDTHS:
    m1=w-1
    body=(f"module addsub_cla{w}(input [{m1}:0] a, input [{m1}:0] b, input sub, output [{m1}:0] result, output cout, output ovf);\n"
          +ASDEF+
          f"    wire [{m1}:0] bx = b ^ {{{w}{{sub}}}};\n    wire co;\n"
          f"    claadd{w} u(.a(a),.b(bx),.cin(sub),.sum(result),.cout(co));\n"
          f"    assign cout=co; assign ovf=(a[{m1}]==bx[{m1}])&(result[{m1}]!=a[{m1}]);\nendmodule\n\n"+cla_unit(w))
    emit(f"addsub_cla{w}", body, [f"{w}-bit add/sub on CLA core."])

# addsub_prefix on Kogge-Stone core
def ks_unit(w):
    ok,stages=verify("kogge_stone",w); assert ok
    BLACK=("module bcz(input gk,input pk,input gj,input pj,output g,output p);\n    assign g=gk|(pk&gj);assign p=pk&pj;\nendmodule\n")
    L=[f"module ksadd{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(f"    wire [{w-1}:0] p0,g0;")
    for i in range(w): L.append(f"    assign p0[{i}]=a[{i}]^b[{i}]; assign g0[{i}]=a[{i}]&b[{i}];")
    pg,pp="g0","p0"
    for lvl,st in enumerate(stages):
        gn=f"g{lvl+1}";pn=f"p{lvl+1}"; L.append(f"    wire [{w-1}:0] {gn},{pn};")
        for i in range(w):
            if i in st:
                hi,lo=st[i]; L.append(f"    bcz c{lvl}_{i}(.gk({pg}[{hi}]),.pk({pp}[{hi}]),.gj({pg}[{lo}]),.pj({pp}[{lo}]),.g({gn}[{i}]),.p({pn}[{i}]));")
            else: L.append(f"    assign {gn}[{i}]={pg}[{i}]; assign {pn}[{i}]={pp}[{i}];")
        pg,pp=gn,pn
    L.append(f"    wire [{w}:0] c; assign c[0]=cin;")
    for i in range(w): L.append(f"    assign c[{i+1}]={pg}[{i}]|({pp}[{i}]&cin);")
    L.append(f"    assign cout=c[{w}];")
    for i in range(w): L.append(f"    assign sum[{i}]=p0[{i}]^c[{i}];")
    L.append("endmodule")
    return "\n".join(L)+"\n\n"+BLACK
for w in WIDTHS:
    m1=w-1
    body=(f"module addsub_prefix{w}(input [{m1}:0] a, input [{m1}:0] b, input sub, output [{m1}:0] result, output cout, output ovf);\n"
          +ASDEF+
          f"    wire [{m1}:0] bx=b^{{{w}{{sub}}}}; wire co;\n"
          f"    ksadd{w} u(.a(a),.b(bx),.cin(sub),.sum(result),.cout(co));\n"
          f"    assign cout=co; assign ovf=(a[{m1}]==bx[{m1}])&(result[{m1}]!=a[{m1}]);\nendmodule\n\n"+ks_unit(w))
    emit(f"addsub_prefix{w}", body, [f"{w}-bit add/sub on Kogge-Stone prefix adder."])

# saturating add/sub
for w in WIDTHS:
    m1=w-1
    emit(f"addsub_saturating_unsigned{w}",
         f"module addsub_saturating_unsigned{w}(input [{m1}:0] a, input [{m1}:0] b, input sub, output [{m1}:0] result);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define sub input {COL['sel']}   // define result output {COL['out']}\n"
         f"    wire [{w}:0] add = {{1'b0,a}} + {{1'b0,b}};\n"
         f"    wire        bge = (b > a);\n"
         f"    wire [{m1}:0] dif = a - b;\n"
         f"    assign result = sub ? (bge ? {{{w}{{1'b0}}}} : dif)\n"
         f"                        : (add[{w}] ? {{{w}{{1'b1}}}} : add[{m1}:0]);\nendmodule\n",
         [f"{w}-bit unsigned saturating add/sub (clamp 0..max)."])
    emit(f"addsub_saturating_signed{w}",
         f"module addsub_saturating_signed{w}(input signed [{m1}:0] a, input signed [{m1}:0] b, input sub, output signed [{m1}:0] result);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define sub input {COL['sel']}   // define result output {COL['out']}\n"
         f"    wire signed [{w}:0] ext = sub ? (a - b) : (a + b);\n"
         f"    wire signed [{m1}:0] maxv = {{1'b0,{{{m1}{{1'b1}}}}}};\n"
         f"    wire signed [{m1}:0] minv = {{1'b1,{{{m1}{{1'b0}}}}}};\n"
         f"    assign result = (ext > maxv) ? maxv : (ext < minv) ? minv : ext[{m1}:0];\nendmodule\n",
         [f"{w}-bit signed saturating add/sub (clamp to +max/-min)."])

# negation, abs
for w in WIDTHS:
    m1=w-1
    emit(f"neg_twos{w}",
         f"module neg_twos{w}(input [{m1}:0] a, output [{m1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    assign y = (~a) + 1'b1;   // two's complement negate\nendmodule\n",
         [f"{w}-bit two's-complement negate (y = -a)."])
    emit(f"neg_ones{w}",
         f"module neg_ones{w}(input [{m1}:0] a, output [{m1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    assign y = ~a;            // one's complement\nendmodule\n",
         [f"{w}-bit one's-complement negate (y = ~a)."])
    emit(f"abs_twos{w}",
         f"module abs_twos{w}(input signed [{m1}:0] a, output [{m1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    assign y = a[{m1}] ? ((~a) + 1'b1) : a;   // |a|\nendmodule\n",
         [f"{w}-bit two's-complement absolute value."])

# sign/zero extension
for (lo,hi) in [(4,8),(8,16),(16,32)]:
    emit(f"sign_extend{lo}_to{hi}",
         f"module sign_extend{lo}_to{hi}(input [{lo-1}:0] a, output [{hi-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    assign y = {{{{{hi-lo}{{a[{lo-1}]}}}}, a}};   // replicate sign bit\nendmodule\n",
         [f"Sign-extend {lo}-bit to {hi}-bit."])
    emit(f"zero_extend{lo}_to{hi}",
         f"module zero_extend{lo}_to{hi}(input [{lo-1}:0] a, output [{hi-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    assign y = {{{{{hi-lo}{{1'b0}}}}, a}};   // pad with zeros\nendmodule\n",
         [f"Zero-extend {lo}-bit to {hi}-bit."])

print("addsub/neg/ext generated")
