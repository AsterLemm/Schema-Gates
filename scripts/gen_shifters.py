import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS
OUT=os.path.join(os.path.dirname(__file__),"..","src","shifters")
OUTB=os.path.join(os.path.dirname(__file__),"..","src","bit_manipulation")
def emit(d,name,body,desc): write(os.path.join(d,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")

MUX2=("module mux2_1(input d0, input d1, input sel, output y);\n    assign y = sel ? d1 : d0;\nendmodule\n")

def barrel(w, direction, arith=False):
    """Barrel shifter as log2(w) mux stages, each shifting by a power of two."""
    sb=int(math.log2(w))
    name={("L",False):f"barrel_left{w}",("R",False):f"barrel_right{w}",
          }.get((direction,arith))
    L=[f"module {name}(input [{w-1}:0] a, input [{sb-1}:0] sh, output [{w-1}:0] y);"]
    L.append(f"    // define a input {COL['a']}   // define sh input {COL['sel']}   // define y output {COL['out']}")
    prev="a"
    for s in range(sb):
        shift=1<<s
        cur=f"st{s}"
        L.append(f"    wire [{w-1}:0] {cur};")
        for bit in range(w):
            if direction=="L":
                src = bit-shift
                if src>=0:
                    L.append(f"    mux2_1 m{s}_{bit}(.d0({prev}[{bit}]), .d1({prev}[{src}]), .sel(sh[{s}]), .y({cur}[{bit}]));")
                else:
                    L.append(f"    mux2_1 m{s}_{bit}(.d0({prev}[{bit}]), .d1(1'b0), .sel(sh[{s}]), .y({cur}[{bit}]));")
            else: # right
                src = bit+shift
                fill = f"{prev}[{w-1}]" if arith else "1'b0"
                if src<w:
                    L.append(f"    mux2_1 m{s}_{bit}(.d0({prev}[{bit}]), .d1({prev}[{src}]), .sel(sh[{s}]), .y({cur}[{bit}]));")
                else:
                    L.append(f"    mux2_1 m{s}_{bit}(.d0({prev}[{bit}]), .d1({fill}), .sel(sh[{s}]), .y({cur}[{bit}]));")
        prev=cur
    L.append(f"    assign y = {prev};")
    L.append("endmodule")
    return name,"\n".join(L)+"\n\n"+MUX2

for w in WIDTHS:
    n,b=barrel(w,"L"); emit(OUT,n,b,[f"{w}-bit barrel left shifter (log2 mux stages)."])
    n,b=barrel(w,"R"); emit(OUT,n,b,[f"{w}-bit barrel right shifter (logical)."])

# bidirectional barrel: dir selects L/R
def barrel_bidir(w):
    sb=int(math.log2(w))
    name=f"barrel_bidir{w}"
    L=[f"module {name}(input [{w-1}:0] a, input [{sb-1}:0] sh, input dir, output [{w-1}:0] y);"]
    L.append(f"    // define a input {COL['a']}   // define sh input {COL['sel']}   // define dir input {COL['sel']}   // define y output {COL['out']}")
    L.append(f"    // dir=0 left, dir=1 right (logical)")
    L.append(f"    wire [{w-1}:0] l = a << sh;")
    L.append(f"    wire [{w-1}:0] r = a >> sh;")
    L.append(f"    assign y = dir ? r : l;")
    L.append("endmodule")
    return name,"\n".join(L)+"\n"
for w in WIDTHS:
    n,b=barrel_bidir(w); emit(OUT,n,b,[f"{w}-bit bidirectional barrel shifter."])

# simple named shifters (variable amount)
for w in WIDTHS:
    sb=int(math.log2(w))
    emit(OUT,f"shift_left_logical{w}",
         f"module shift_left_logical{w}(input [{w-1}:0] a, input [{sb-1}:0] sh, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define sh input {COL['sel']}   // define y output {COL['out']}\n"
         f"    assign y = a << sh;\nendmodule\n",[f"{w}-bit logical left shift."])
    emit(OUT,f"shift_right_logical{w}",
         f"module shift_right_logical{w}(input [{w-1}:0] a, input [{sb-1}:0] sh, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define sh input {COL['sel']}   // define y output {COL['out']}\n"
         f"    assign y = a >> sh;\nendmodule\n",[f"{w}-bit logical right shift."])
    emit(OUT,f"shift_right_arithmetic{w}",
         f"module shift_right_arithmetic{w}(input signed [{w-1}:0] a, input [{sb-1}:0] sh, output signed [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define sh input {COL['sel']}   // define y output {COL['out']}\n"
         f"    assign y = a >>> sh;\nendmodule\n",[f"{w}-bit arithmetic right shift (sign-preserving)."])

# rotators
for w in WIDTHS:
    sb=int(math.log2(w))
    emit(OUT,f"rotate_left{w}",
         f"module rotate_left{w}(input [{w-1}:0] a, input [{sb-1}:0] sh, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define sh input {COL['sel']}   // define y output {COL['out']}\n"
         f"    assign y = (a << sh) | (a >> ({w}-sh));\nendmodule\n",[f"{w}-bit rotate left."])
    emit(OUT,f"rotate_right{w}",
         f"module rotate_right{w}(input [{w-1}:0] a, input [{sb-1}:0] sh, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define sh input {COL['sel']}   // define y output {COL['out']}\n"
         f"    assign y = (a >> sh) | (a << ({w}-sh));\nendmodule\n",[f"{w}-bit rotate right."])
    emit(OUT,f"rotate_bidir{w}",
         f"module rotate_bidir{w}(input [{w-1}:0] a, input [{sb-1}:0] sh, input dir, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define sh input {COL['sel']}   // define dir input {COL['sel']}   // define y output {COL['out']}\n"
         f"    wire [{w-1}:0] rl = (a << sh) | (a >> ({w}-sh));\n"
         f"    wire [{w-1}:0] rr = (a >> sh) | (a << ({w}-sh));\n"
         f"    assign y = dir ? rr : rl;\nendmodule\n",[f"{w}-bit bidirectional rotate."])

# ---- bit manipulation --------------------------------------------------
for w in WIDTHS:
    # bit_reverse
    rev="{"+", ".join(f"a[{i}]" for i in range(w))+"}"
    emit(OUTB,f"bit_reverse{w}",
         f"module bit_reverse{w}(input [{w-1}:0] a, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    assign y = {rev};\nendmodule\n",[f"{w}-bit bit-reverse."])
    sb=int(math.log2(w))
    # mask_low / mask_high
    emit(OUTB,f"mask_low{w}",
         f"module mask_low{w}(input [{sb}:0] n, output [{w-1}:0] y);\n"
         f"    // define n input {COL['sel']}   // define y output {COL['out']}\n"
         f"    assign y = ({{{w}{{1'b1}}}} >> ({w}-n)) & {{{w}{{|n}}}} | (n=={w} ? {{{w}{{1'b1}}}} : ( ({{{w}'b1}} << n) - 1'b1));\nendmodule\n",
         [f"{w}-bit low-mask (n low bits set)."])
    emit(OUTB,f"mask_high{w}",
         f"module mask_high{w}(input [{sb}:0] n, output [{w-1}:0] y);\n"
         f"    // define n input {COL['sel']}   // define y output {COL['out']}\n"
         f"    assign y = ~(({{{w}'b1}} << ({w}-n)) - 1'b1) ;\nendmodule\n",
         [f"{w}-bit high-mask (n high bits set)."])
    # set/clear/toggle bit
    emit(OUTB,f"set_bit{w}",
         f"module set_bit{w}(input [{w-1}:0] a, input [{sb-1}:0] pos, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define pos input {COL['sel']}   // define y output {COL['out']}\n"
         f"    assign y = a | ({{{w}'b1}} << pos);\nendmodule\n",[f"{w}-bit set-bit at pos."])
    emit(OUTB,f"clear_bit{w}",
         f"module clear_bit{w}(input [{w-1}:0] a, input [{sb-1}:0] pos, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define pos input {COL['sel']}   // define y output {COL['out']}\n"
         f"    assign y = a & ~({{{w}'b1}} << pos);\nendmodule\n",[f"{w}-bit clear-bit at pos."])
    emit(OUTB,f"toggle_bit{w}",
         f"module toggle_bit{w}(input [{w-1}:0] a, input [{sb-1}:0] pos, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define pos input {COL['sel']}   // define y output {COL['out']}\n"
         f"    assign y = a ^ ({{{w}'b1}} << pos);\nendmodule\n",[f"{w}-bit toggle-bit at pos."])
    # extract_field / insert_field
    emit(OUTB,f"extract_field{w}",
         f"module extract_field{w}(input [{w-1}:0] a, input [{sb-1}:0] pos, input [{sb}:0] len, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define pos input {COL['sel']}   // define len input {COL['sel']}   // define y output {COL['out']}\n"
         f"    wire [{w-1}:0] m = ({{{w}'b1}} << len) - 1'b1;\n"
         f"    assign y = (a >> pos) & m;\nendmodule\n",[f"{w}-bit extract bitfield (len bits at pos)."])
    emit(OUTB,f"insert_field{w}",
         f"module insert_field{w}(input [{w-1}:0] a, input [{w-1}:0] v, input [{sb-1}:0] pos, input [{sb}:0] len, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define v input {COL['b']}   // define pos input {COL['sel']}   // define len input {COL['sel']}   // define y output {COL['out']}\n"
         f"    wire [{w-1}:0] m = (({{{w}'b1}} << len) - 1'b1) << pos;\n"
         f"    assign y = (a & ~m) | ((v << pos) & m);\nendmodule\n",[f"{w}-bit insert bitfield."])

# nibble/byte swaps
for w in (8,16,32):
    # nibble_swap: swap adjacent 4-bit nibbles
    parts=[]
    for k in range(0,w,8):
        parts.append(f"a[{k+3}:{k}]")     # low nibble -> high
        parts.append(f"a[{k+7}:{k+4}]")   # high nibble -> low
    parts=parts[::-1]
    emit(OUTB,f"nibble_swap{w}",
         f"module nibble_swap{w}(input [{w-1}:0] a, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    assign y = {{{', '.join(parts)}}};\nendmodule\n",[f"{w}-bit nibble swap (within each byte)."])
for w in (16,32):
    bytes_=[f"a[{k+7}:{k}]" for k in range(0,w,8)]
    emit(OUTB,f"byte_swap{w}",
         f"module byte_swap{w}(input [{w-1}:0] a, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    assign y = {{{', '.join(bytes_)}}};\nendmodule\n",[f"{w}-bit byte swap (endianness reverse)."])

print("shifters + bit-manip generated")
