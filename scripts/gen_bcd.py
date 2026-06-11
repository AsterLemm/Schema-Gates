import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL
OUTB=os.path.join(os.path.dirname(__file__),"..","src","bcd")
OUTD=os.path.join(os.path.dirname(__file__),"..","src","display")
def emitb(name,body,desc): write(os.path.join(OUTB,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")
def emitd(name,body,desc): write(os.path.join(OUTD,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")

# ---- §12 binary -> BCD via double-dabble; widths -> digit counts -------
BIN2BCD = {4:2, 8:3, 16:5, 32:10}   # binary width -> #BCD digits needed
for bw,nd in BIN2BCD.items():
    ow=nd*4
    L=[f"module bin_to_bcd{bw}(input [{bw-1}:0] a, output [{ow-1}:0] bcd);"]
    L.append(f"    // define a input {COL['a']}   // define bcd output {COL['out']}")
    L.append(f"    // Double-dabble (shift-and-add-3) binary to {nd}-digit BCD.")
    L.append(f"    integer k; reg [{ow+bw-1}:0] shift; integer d;")
    L.append(f"    always @(*) begin")
    L.append(f"        shift = 0; shift[{bw-1}:0] = a;")
    L.append(f"        for (k=0; k<{bw}; k=k+1) begin")
    for d in range(nd):
        lo=bw+d*4; hi=lo+3
        L.append(f"            if (shift[{hi}:{lo}] >= 5) shift[{hi}:{lo}] = shift[{hi}:{lo}] + 4'd3;")
    L.append(f"            shift = shift << 1;")
    L.append(f"        end")
    L.append(f"    end")
    L.append(f"    assign bcd = shift[{ow+bw-1}:{bw}];")
    L.append("endmodule")
    emitb(f"bin_to_bcd{bw}", "\n".join(L)+"\n", [f"{bw}-bit binary -> {nd}-digit BCD (double-dabble)."])
    # bcd -> binary (STRUCTURAL: digit*10^i via shift-add, ripple-adder sum)
    POW10=[1,10,100,1000,10000,100000,1000000,10000000,100000000,1000000000]
    W=bw+4
    Lb=[f"module bcd_to_bin{bw}(input [{ow-1}:0] bcd, output [{bw-1}:0] a);"]
    Lb.append(f"    // define bcd input {COL['a']}   // define a output {COL['out']}")
    allterms=[]
    for d in range(nd):
        lo=d*4; hi=lo+3; k=POW10[d]
        sig=f"{{{W-4}'b0, bcd[{hi}:{lo}]}}"
        for bp in [i for i in range(k.bit_length()) if (k>>i)&1]:
            wn=f"t{d}_{bp}"; Lb.append(f"    wire [{W-1}:0] {wn} = ({sig}) << {bp};"); allterms.append(wn)
    if len(allterms)==1:
        Lb.append(f"    wire [{W-1}:0] acc0 = {allterms[0]};"); last="acc0"
    else:
        last=allterms[0]
        for i2,t in enumerate(allterms[1:]):
            nxt=f"acc{i2}"; Lb.append(f"    wire [{W-1}:0] {nxt}; wire c{i2};")
            Lb.append(f"    bcdadd{W} ad{i2}(.a({last}),.b({t}),.cin(1'b0),.sum({nxt}),.cout(c{i2}));"); last=nxt
    Lb.append(f"    assign a = {last}[{bw-1}:0];")
    Lb.append("endmodule")
    import _structural as _S
    bodyb="\n".join(Lb)+"\n\n"+_S.ripple_adder(W,f"bcdadd{W}")+"\n"+_S.leaf_adders()
    emitb(f"bcd_to_bin{bw}", bodyb, [f"{nd}-digit BCD -> {bw}-bit binary.","Structural digit*10^i shift-add; no * operator."])

# ---- §13 BCD arithmetic: digit widths 1/2/4/8 + bit-mapped aliases -----
def bcd_add_digits(nd):
    """nd BCD digits; ripple decimal adder with +6 correction."""
    w=nd*4
    L=[f"module bcd_add{nd}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);"]
    L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define cin input {COL['cin']}")
    L.append(f"    // define sum output {COL['out']}   // define cout output {COL['flag']}")
    L.append(f"    wire [{nd}:0] dc; assign dc[0]=cin;   // decimal carries")
    for d in range(nd):
        lo=d*4; hi=lo+3
        L.append(f"    wire [4:0] raw{d} = a[{hi}:{lo}] + b[{hi}:{lo}] + dc[{d}];")
        L.append(f"    wire corr{d} = (raw{d} > 9);")
        L.append(f"    wire [4:0] adj{d} = corr{d} ? (raw{d} + 5'd6) : raw{d};")
        L.append(f"    assign sum[{hi}:{lo}] = adj{d}[3:0];")
        L.append(f"    assign dc[{d+1}] = corr{d};")
    L.append(f"    assign cout = dc[{nd}];")
    L.append("endmodule")
    return "\n".join(L)+"\n"
def bcd_sub_digits(nd):
    w=nd*4
    L=[f"module bcd_sub{nd}(input [{w-1}:0] a, input [{w-1}:0] b, input bin, output [{w-1}:0] diff, output bout);"]
    L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define bin input {COL['cin']}")
    L.append(f"    // define diff output {COL['out']}   // define bout output {COL['flag']}")
    L.append(f"    wire [{nd}:0] db; assign db[0]=bin;")
    for d in range(nd):
        lo=d*4; hi=lo+3
        L.append(f"    wire [4:0] raw{d} = a[{hi}:{lo}] - b[{hi}:{lo}] - db[{d}];")
        L.append(f"    wire borrow{d} = raw{d}[4];")
        L.append(f"    wire [4:0] adj{d} = borrow{d} ? (raw{d} - 5'd6) : raw{d};")
        L.append(f"    assign diff[{hi}:{lo}] = adj{d}[3:0];")
        L.append(f"    assign db[{d+1}] = borrow{d};")
    L.append(f"    assign bout = db[{nd}];")
    L.append("endmodule")
    return "\n".join(L)+"\n"

for nd in [1,2,4,8]:
    emitb(f"bcd_add{nd}", bcd_add_digits(nd), [f"{nd}-digit BCD adder (+6 decimal correction)."])
    emitb(f"bcd_sub{nd}", bcd_sub_digits(nd), [f"{nd}-digit BCD subtractor (-6 decimal correction)."])

# bit-mapped aliases: 4/8/16/32 bits -> 1/2/4/8 digits
BITMAP={4:1,8:2,16:4,32:8}
for bits,nd in BITMAP.items():
    w=bits
    # alias modules that wrap the digit version
    emitb(f"bcd_add_bits{bits}",
          f"module bcd_add_bits{bits}(input [{w-1}:0] a, input [{w-1}:0] b, input cin, output [{w-1}:0] sum, output cout);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define cin input {COL['cin']}\n"
          f"    // define sum output {COL['out']}   // define cout output {COL['flag']}\n"
          f"    // {bits}-bit = {nd}-digit BCD\n"
          + bcd_add_digits(nd).replace(f"module bcd_add{nd}(", f"// inlined bcd_add{nd}\n    bcd_add{nd}_inner inner(") .split("\n")[0] # placeholder
          , [""])

# The alias approach above is messy; do clean self-contained inline instead:
import re
def bcd_add_named(modname, nd):
    body=bcd_add_digits(nd)
    return body.replace(f"module bcd_add{nd}(", f"module {modname}(")
def bcd_sub_named(modname, nd):
    body=bcd_sub_digits(nd)
    return body.replace(f"module bcd_sub{nd}(", f"module {modname}(")
for bits,nd in BITMAP.items():
    emitb(f"bcd_add_bits{bits}", bcd_add_named(f"bcd_add_bits{bits}", nd), [f"{bits}-bit ({nd}-digit) BCD adder."])
    emitb(f"bcd_sub_bits{bits}", bcd_sub_named(f"bcd_sub_bits{bits}", nd), [f"{bits}-bit ({nd}-digit) BCD subtractor."])

# bcd digit validity / nine's & ten's complement
for nd in [1,2,4,8]:
    w=nd*4
    checks=" & ".join(f"(a[{d*4+3}:{d*4}] <= 9)" for d in range(nd))
    emitb(f"bcd_valid{nd}",
          f"module bcd_valid{nd}(input [{w-1}:0] a, output valid);\n"
          f"    // define a input {COL['a']}   // define valid output {COL['status']}\n"
          f"    assign valid = {checks};\nendmodule\n",
          [f"{nd}-digit BCD validity (each nibble <= 9)."])
    L=[f"module bcd_nines_complement{nd}(input [{w-1}:0] a, output [{w-1}:0] y);"]
    L.append(f"    // define a input {COL['a']}   // define y output {COL['out']}")
    for d in range(nd):
        lo=d*4;hi=lo+3
        L.append(f"    assign y[{hi}:{lo}] = 4'd9 - a[{hi}:{lo}];")
    L.append("endmodule")
    emitb(f"bcd_nines_complement{nd}", "\n".join(L)+"\n", [f"{nd}-digit BCD nine's complement."])

# ---- §14 Display: 7-seg and ASCII -------------------------------------
emitd("bin_to_7seg",
     "module bin_to_7seg(input [3:0] a, output reg [6:0] seg);\n"
     "    // define a input 80.160.255   // define seg output 120.255.160\n"
     "    // seg = {g,f,e,d,c,b,a}, active-high, hex 0-F\n"
     "    always @(*) case(a)\n"
     "        4'h0: seg=7'b0111111; 4'h1: seg=7'b0000110; 4'h2: seg=7'b1011011; 4'h3: seg=7'b1001111;\n"
     "        4'h4: seg=7'b1100110; 4'h5: seg=7'b1101101; 4'h6: seg=7'b1111101; 4'h7: seg=7'b0000111;\n"
     "        4'h8: seg=7'b1111111; 4'h9: seg=7'b1101111; 4'ha: seg=7'b1110111; 4'hb: seg=7'b1111100;\n"
     "        4'hc: seg=7'b0111001; 4'hd: seg=7'b1011110; 4'he: seg=7'b1111001; 4'hf: seg=7'b1110001;\n"
     "    endcase\nendmodule\n",
     ["4-bit hex to 7-segment decoder (active-high)."])
emitd("bcd_to_7seg",
     "module bcd_to_7seg(input [3:0] a, output reg [6:0] seg);\n"
     "    // define a input 80.160.255   // define seg output 120.255.160\n"
     "    always @(*) case(a)\n"
     "        4'd0: seg=7'b0111111; 4'd1: seg=7'b0000110; 4'd2: seg=7'b1011011; 4'd3: seg=7'b1001111;\n"
     "        4'd4: seg=7'b1100110; 4'd5: seg=7'b1101101; 4'd6: seg=7'b1111101; 4'd7: seg=7'b0000111;\n"
     "        4'd8: seg=7'b1111111; 4'd9: seg=7'b1101111; default: seg=7'b0000000;\n"
     "    endcase\nendmodule\n",
     ["BCD digit (0-9) to 7-segment decoder (blank if >9)."])
emitd("seg7_with_dp",
     "module seg7_with_dp(input [3:0] a, input dp, output [7:0] seg);\n"
     "    // define a input 80.160.255   // define dp input 255.230.80   // define seg output 120.255.160\n"
     "    reg [6:0] base;\n"
     "    always @(*) case(a)\n"
     "        4'h0: base=7'b0111111; 4'h1: base=7'b0000110; 4'h2: base=7'b1011011; 4'h3: base=7'b1001111;\n"
     "        4'h4: base=7'b1100110; 4'h5: base=7'b1101101; 4'h6: base=7'b1111101; 4'h7: base=7'b0000111;\n"
     "        4'h8: base=7'b1111111; 4'h9: base=7'b1101111; 4'ha: base=7'b1110111; 4'hb: base=7'b1111100;\n"
     "        4'hc: base=7'b0111001; 4'hd: base=7'b1011110; 4'he: base=7'b1111001; 4'hf: base=7'b1110001;\n"
     "    endcase\n    assign seg={dp,base};\nendmodule\n",
     ["7-segment hex decoder with decimal point."])
emitd("bin_to_ascii_digit",
     "module bin_to_ascii_digit(input [3:0] a, output [7:0] ascii);\n"
     "    // define a input 80.160.255   // define ascii output 120.255.160\n"
     "    // 0-9 -> '0'..'9', a-f -> 'A'..'F'\n"
     "    assign ascii = (a < 10) ? (8'h30 + a) : (8'h41 + (a - 10));\nendmodule\n",
     ["4-bit hex nibble to ASCII character code."])
emitd("ascii_digit_to_bin",
     "module ascii_digit_to_bin(input [7:0] ascii, output [3:0] a, output valid);\n"
     "    // define ascii input 80.160.255   // define a output 120.255.160   // define valid output 255.255.255\n"
     "    wire is_dig = (ascii >= 8'h30) && (ascii <= 8'h39);\n"
     "    wire is_uc  = (ascii >= 8'h41) && (ascii <= 8'h46);\n"
     "    wire is_lc  = (ascii >= 8'h61) && (ascii <= 8'h66);\n"
     "    assign a = is_dig ? (ascii - 8'h30) : is_uc ? (ascii - 8'h41 + 4'd10) : is_lc ? (ascii - 8'h61 + 4'd10) : 4'd0;\n"
     "    assign valid = is_dig | is_uc | is_lc;\nendmodule\n",
     ["ASCII hex character to 4-bit nibble (+valid)."])

print("bcd + display generated")
