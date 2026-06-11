import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS

OUT=os.path.join(os.path.dirname(__file__),"..","src","comparators")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")

def hdr(name, aw, outs, signed=False):
    # outs: list of output port names
    op=", ".join("output "+o for o in outs)
    s="signed " if signed else ""
    return (f"module {name}(input {s}[{aw-1}:0] a, input {s}[{aw-1}:0] b, {op});\n"
            f"    // define a input {COL['a']}   // define b input {COL['b']}\n")

for w in WIDTHS:
    # eq / neq
    emit(f"eq{w}",  hdr(f"eq{w}",w,["eq"])  +f"    // define eq output {COL['out']}\n    assign eq  = (a == b);\nendmodule\n",[f"Equality, {w}-bit (eq=1 iff a==b)."])
    emit(f"neq{w}", hdr(f"neq{w}",w,["neq"])+f"    // define neq output {COL['out']}\n    assign neq = (a != b);\nendmodule\n",[f"Inequality, {w}-bit."])
    # unsigned magnitude
    for op,expr,nm in [("lt","a <  b","less-than"),("lte","a <= b","less-or-equal"),
                       ("gt","a >  b","greater-than"),("gte","a >= b","greater-or-equal")]:
        emit(f"{op}_unsigned{w}", hdr(f"{op}_unsigned{w}",w,["y"])+f"    // define y output {COL['out']}\n    assign y = ({expr});\nendmodule\n",[f"Unsigned {nm}, {w}-bit."])
    # signed magnitude
    for op,expr,nm in [("lt","a <  b","less-than"),("lte","a <= b","less-or-equal"),
                       ("gt","a >  b","greater-than"),("gte","a >= b","greater-or-equal")]:
        emit(f"{op}_signed{w}", hdr(f"{op}_signed{w}",w,["y"],signed=True)+f"    // define y output {COL['out']}\n    assign y = ({expr});\nendmodule\n",[f"Signed {nm}, {w}-bit (two's complement)."])

# detectors (single operand a)
def det(name,w,expr,desc,outname="y"):
    emit(name,
         f"module {name}(input [{w-1}:0] a, output {outname});\n"
         f"    // define a input {COL['a']}   // define {outname} output {COL['status']}\n"
         f"    assign {outname} = {expr};\nendmodule\n",[desc])
for w in WIDTHS:
    det(f"zero_detect{w}",w,"~(|a)",f"Zero detect, {w}-bit (1 iff a==0).")
    det(f"nonzero_detect{w}",w,"|a",f"Non-zero detect, {w}-bit.")
    det(f"all_ones_detect{w}",w,"&a",f"All-ones detect, {w}-bit.")
    det(f"sign_detect{w}",w,f"a[{w-1}]",f"Sign detect, {w}-bit (MSB).")
    det(f"even_detect{w}",w,"~a[0]",f"Even detect, {w}-bit (LSB==0).")
    det(f"odd_detect{w}",w,"a[0]",f"Odd detect, {w}-bit (LSB==1).")

# arithmetic flags (take operands / results as appropriate)
for w in WIDTHS:
    # carry_flag: carry out of a+b (unsigned). Provide a,b,cin.
    emit(f"carry_flag{w}",
         f"module carry_flag{w}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output carry);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define cin input {COL['cin']}   // define carry output {COL['flag']}\n"
         f"    wire [{w}:0] ext;\n"
         f"    assign ext = a + b + cin;\n"
         f"    assign carry = ext[{w}];\nendmodule\n",[f"Carry flag for a+b+cin, {w}-bit."])
    emit(f"borrow_flag{w}",
         f"module borrow_flag{w}(input [{w-1}:0] a, input [{w-1}:0] b, input bin, output borrow);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define bin input {COL['cin']}   // define borrow output {COL['flag']}\n"
         f"    wire [{w}:0] ext;\n"
         f"    assign ext = {{1'b0, a}} - {{1'b0, b}} - bin;\n"
         f"    assign borrow = ext[{w}];   // underflow bit\nendmodule\n",[f"Borrow flag for a-b-bin, {w}-bit."])
    emit(f"overflow_add{w}",
         f"module overflow_add{w}(input [{w-1}:0] a, input [{w-1}:0] b, output ovf);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define ovf output {COL['flag']}\n"
         f"    wire [{w-1}:0] s = a + b;\n"
         f"    assign ovf = (a[{w-1}] == b[{w-1}]) & (s[{w-1}] != a[{w-1}]);\nendmodule\n",[f"Signed add overflow, {w}-bit."])
    emit(f"overflow_sub{w}",
         f"module overflow_sub{w}(input [{w-1}:0] a, input [{w-1}:0] b, output ovf);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define ovf output {COL['flag']}\n"
         f"    wire [{w-1}:0] d = a - b;\n"
         f"    assign ovf = (a[{w-1}] != b[{w-1}]) & (d[{w-1}] != a[{w-1}]);\nendmodule\n",[f"Signed sub overflow, {w}-bit."])
    det(f"negative_flag{w}",w,f"a[{w-1}]",f"Negative flag, {w}-bit (result MSB).",outname="neg")
    det(f"zero_flag{w}",w,"~(|a)",f"Zero flag, {w}-bit (result==0).",outname="zero")

print("comparators generated")
