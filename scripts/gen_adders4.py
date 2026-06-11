import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS, m_full_adder, m_half_adder
OUT=os.path.join(os.path.dirname(__file__),"..","src","adders")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")
FA=m_full_adder()+"\n"+m_half_adder()

for w in WIDTHS:
    m1=w-1
    # incrementer (a+1) structural: half-adder chain
    L=[f"module inc{w}(input [{m1}:0] a, output [{m1}:0] y, output cout);"]
    L.append(f"    // define a input {COL['a']}   // define y output {COL['out']}   // define cout output {COL['flag']}")
    L.append(f"    wire [{w}:0] c; assign c[0]=1'b1;")
    for i in range(w):
        L.append(f"    half_adder ha{i}(.a(a[{i}]),.b(c[{i}]),.sum(y[{i}]),.carry(c[{i+1}]));")
    L.append(f"    assign cout=c[{w}];")
    L.append("endmodule")
    emit(f"inc{w}", "\n".join(L)+"\n\n"+m_half_adder(), [f"{w}-bit incrementer (y=a+1), half-adder carry chain."])

    # decrementer (a-1) structural: subtract 1 = add all-ones with cin handled
    L=[f"module dec{w}(input [{m1}:0] a, output [{m1}:0] y, output bout);"]
    L.append(f"    // define a input {COL['a']}   // define y output {COL['out']}   // define bout output {COL['flag']}")
    L.append(f"    wire [{w}:0] bw; assign bw[0]=1'b1;   // borrow chain, borrow-in=1 (subtract 1)")
    for i in range(w):
        L.append(f"    assign y[{i}]    = a[{i}] ^ bw[{i}];")
        L.append(f"    assign bw[{i+1}] = (~a[{i}]) & bw[{i}];")
    L.append(f"    assign bout=bw[{w}];")
    L.append("endmodule")
    emit(f"dec{w}", "\n".join(L)+"\n", [f"{w}-bit decrementer (y=a-1), borrow chain."])

    # add_one (alias of inc, but separate catalog name; behavioral-free)
    emit(f"add_one{w}",
         f"module add_one{w}(input [{m1}:0] a, output [{m1}:0] y, output cout);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}   // define cout output {COL['flag']}\n"
         f"    wire [{w}:0] c; assign c[0]=1'b1;\n"
         + "".join(f"    half_adder ha{i}(.a(a[{i}]),.b(c[{i}]),.sum(y[{i}]),.carry(c[{i+1}]));\n" for i in range(w))
         + f"    assign cout=c[{w}];\nendmodule\n\n"+m_half_adder(),
         [f"{w}-bit add-one (y=a+1)."])

    # add_const1: add the literal constant 1 (same as add_one); keep distinct name
    emit(f"add_const1{w}",
         f"module add_const1{w}(input [{m1}:0] a, output [{m1}:0] y, output cout);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}   // define cout output {COL['flag']}\n"
         f"    wire [{w}:0] c; assign c[0]=1'b1;\n"
         + "".join(f"    half_adder ha{i}(.a(a[{i}]),.b(c[{i}]),.sum(y[{i}]),.carry(c[{i+1}]));\n" for i in range(w))
         + f"    assign cout=c[{w}];\nendmodule\n\n"+m_half_adder(),
         [f"{w}-bit add constant 1 (y=a+1)."])

    # add_modulo: (a+b) mod 2^w  -> just drop carry (ripple)
    L=[f"module add_modulo{w}(input [{m1}:0] a, input [{m1}:0] b, input cin, output [{m1}:0] sum);"]
    L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define cin input {COL['cin']}   // define sum output {COL['out']}")
    L.append(f"    wire [{w}:0] c; assign c[0]=cin;")
    for i in range(w):
        L.append(f"    full_adder fa{i}(.a(a[{i}]),.b(b[{i}]),.cin(c[{i}]),.sum(sum[{i}]),.cout(c[{i+1}]));")
    L.append("endmodule")
    emit(f"add_modulo{w}", "\n".join(L)+"\n\n"+FA, [f"{w}-bit modulo-2^{w} adder (carry-out discarded)."])

    # saturating unsigned: clamp to all-ones on carry
    emit(f"add_saturating_unsigned{w}",
         f"module add_saturating_unsigned{w}(input [{m1}:0] a, input [{m1}:0] b, output [{m1}:0] sum);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define sum output {COL['out']}\n"
         f"    wire [{w}:0] ext = {{1'b0,a}} + {{1'b0,b}};\n"
         f"    assign sum = ext[{w}] ? {{{w}{{1'b1}}}} : ext[{m1}:0];\nendmodule\n",
         [f"{w}-bit unsigned saturating add (clamps to max)."])

    # saturating signed: clamp to max/min on overflow
    emit(f"add_saturating_signed{w}",
         f"module add_saturating_signed{w}(input signed [{m1}:0] a, input signed [{m1}:0] b, output signed [{m1}:0] sum);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define sum output {COL['out']}\n"
         f"    wire signed [{w}:0] ext = a + b;\n"
         f"    wire ovf = (a[{m1}]==b[{m1}]) && (ext[{m1}]!=a[{m1}]);\n"
         f"    assign sum = ovf ? (a[{m1}] ? {{1'b1,{{{m1}{{1'b0}}}}}} : {{1'b0,{{{m1}{{1'b1}}}}}}) : ext[{m1}:0];\nendmodule\n",
         [f"{w}-bit signed saturating add (clamps to +max/-min on overflow)."])

    # ones-complement add (end-around carry folded)
    emit(f"add_ones_complement{w}",
         f"module add_ones_complement{w}(input [{m1}:0] a, input [{m1}:0] b, output [{m1}:0] sum);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define sum output {COL['out']}\n"
         f"    wire [{w}:0] ext = {{1'b0,a}} + {{1'b0,b}};\n"
         f"    assign sum = ext[{m1}:0] + ext[{w}];   // end-around carry\nendmodule\n",
         [f"{w}-bit one's-complement adder (end-around carry)."])

    # end-around-carry adder (explicit EAC name)
    emit(f"add_end_around_carry{w}",
         f"module add_end_around_carry{w}(input [{m1}:0] a, input [{m1}:0] b, output [{m1}:0] sum, output cout);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define sum output {COL['out']}   // define cout output {COL['flag']}\n"
         f"    wire [{w}:0] ext = {{1'b0,a}} + {{1'b0,b}};\n"
         f"    wire [{w}:0] folded = ext[{m1}:0] + ext[{w}];\n"
         f"    assign sum = folded[{m1}:0];\n"
         f"    assign cout = folded[{w}];\nendmodule\n",
         [f"{w}-bit end-around-carry adder."])

print("special adders generated")
