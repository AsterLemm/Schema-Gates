import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS
OUTP=os.path.join(os.path.dirname(__file__),"..","src","popcount_bitscan")
OUTC=os.path.join(os.path.dirname(__file__),"..","src","converters")
def emit(d,name,body,desc): write(os.path.join(d,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")

# ---- §10 popcount / bit-scan ------------------------------------------
for w in WIDTHS:
    ob=int(math.ceil(math.log2(w+1)))  # output bits to hold 0..w
    sumterms="+".join(f"a[{i}]" for i in range(w))
    emit(OUTP,f"popcount{w}",
         f"module popcount{w}(input [{w-1}:0] a, output [{ob-1}:0] count);\n"
         f"    // define a input {COL['a']}   // define count output {COL['out']}\n"
         f"    assign count = {sumterms};\nendmodule\n",[f"{w}-bit population count (number of 1s)."])
    # leading zero count
    idxb=int(math.ceil(math.log2(w+1)))
    emit(OUTP,f"leading_zero_count{w}",
         f"module leading_zero_count{w}(input [{w-1}:0] a, output [{idxb-1}:0] count);\n"
         f"    // define a input {COL['a']}   // define count output {COL['out']}\n"
         f"    integer k; reg [{idxb-1}:0] c; reg done;\n"
         f"    always @(*) begin c=0; done=0;\n"
         f"        for (k={w-1}; k>=0; k=k-1) begin if (a[k]) done=1; if (!done) c=c+1'b1; end\n"
         f"    end\n    assign count=c;\nendmodule\n",[f"{w}-bit leading-zero count."])
    emit(OUTP,f"trailing_zero_count{w}",
         f"module trailing_zero_count{w}(input [{w-1}:0] a, output [{idxb-1}:0] count);\n"
         f"    // define a input {COL['a']}   // define count output {COL['out']}\n"
         f"    integer k; reg [{idxb-1}:0] c; reg done;\n"
         f"    always @(*) begin c=0; done=0;\n"
         f"        for (k=0; k<{w}; k=k+1) begin if (a[k]) done=1; if (!done) c=c+1'b1; end\n"
         f"    end\n    assign count=c;\nendmodule\n",[f"{w}-bit trailing-zero count."])
    emit(OUTP,f"leading_one_count{w}",
         f"module leading_one_count{w}(input [{w-1}:0] a, output [{idxb-1}:0] count);\n"
         f"    // define a input {COL['a']}   // define count output {COL['out']}\n"
         f"    integer k; reg [{idxb-1}:0] c; reg done;\n"
         f"    always @(*) begin c=0; done=0;\n"
         f"        for (k={w-1}; k>=0; k=k-1) begin if (!a[k]) done=1; if (!done) c=c+1'b1; end\n"
         f"    end\n    assign count=c;\nendmodule\n",[f"{w}-bit leading-one count."])
    emit(OUTP,f"trailing_one_count{w}",
         f"module trailing_one_count{w}(input [{w-1}:0] a, output [{idxb-1}:0] count);\n"
         f"    // define a input {COL['a']}   // define count output {COL['out']}\n"
         f"    integer k; reg [{idxb-1}:0] c; reg done;\n"
         f"    always @(*) begin c=0; done=0;\n"
         f"        for (k=0; k<{w}; k=k+1) begin if (!a[k]) done=1; if (!done) c=c+1'b1; end\n"
         f"    end\n    assign count=c;\nendmodule\n",[f"{w}-bit trailing-one count."])
    # first/last one index (+valid)
    emit(OUTP,f"first_one_index{w}",
         f"module first_one_index{w}(input [{w-1}:0] a, output [{idxb-1}:0] idx, output valid);\n"
         f"    // define a input {COL['a']}   // define idx output {COL['out']}   // define valid output {COL['status']}\n"
         f"    integer k; reg [{idxb-1}:0] r; reg f;\n"
         f"    always @(*) begin r=0; f=0;\n"
         f"        for (k=0;k<{w};k=k+1) if (a[k] && !f) begin r=k[{idxb-1}:0]; f=1; end\n"
         f"    end\n    assign idx=r; assign valid=|a;\nendmodule\n",[f"{w}-bit index of first (lowest) set bit."])
    emit(OUTP,f"last_one_index{w}",
         f"module last_one_index{w}(input [{w-1}:0] a, output [{idxb-1}:0] idx, output valid);\n"
         f"    // define a input {COL['a']}   // define idx output {COL['out']}   // define valid output {COL['status']}\n"
         f"    integer k; reg [{idxb-1}:0] r;\n"
         f"    always @(*) begin r=0;\n"
         f"        for (k=0;k<{w};k=k+1) if (a[k]) r=k[{idxb-1}:0];\n"
         f"    end\n    assign idx=r; assign valid=|a;\nendmodule\n",[f"{w}-bit index of last (highest) set bit."])
    emit(OUTP,f"is_power_of_two{w}",
         f"module is_power_of_two{w}(input [{w-1}:0] a, output y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['status']}\n"
         f"    assign y = (|a) & ~(|(a & (a - 1'b1)));\nendmodule\n",[f"{w}-bit power-of-two detector."])

# ---- §11 converters ----------------------------------------------------
for w in WIDTHS:
    emit(OUTC,f"bin_to_gray{w}",
         f"module bin_to_gray{w}(input [{w-1}:0] a, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    assign y = a ^ (a >> 1);\nendmodule\n",[f"{w}-bit binary->Gray."])
    # gray->bin: prefix XOR
    L=[f"module gray_to_bin{w}(input [{w-1}:0] a, output [{w-1}:0] y);"]
    L.append(f"    // define a input {COL['a']}   // define y output {COL['out']}")
    L.append(f"    assign y[{w-1}] = a[{w-1}];")
    for i in range(w-2,-1,-1):
        L.append(f"    assign y[{i}] = y[{i+1}] ^ a[{i}];")
    L.append("endmodule")
    emit(OUTC,f"gray_to_bin{w}","\n".join(L)+"\n",[f"{w}-bit Gray->binary (prefix XOR)."])
    # twos<->ones
    emit(OUTC,f"twos_to_ones{w}",
         f"module twos_to_ones{w}(input signed [{w-1}:0] a, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    assign y = a[{w-1}] ? (a - 1'b1) : a;   // neg: subtract 1\nendmodule\n",[f"{w}-bit two's->one's complement."])
    emit(OUTC,f"ones_to_twos{w}",
         f"module ones_to_twos{w}(input [{w-1}:0] a, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    assign y = a[{w-1}] ? (a + 1'b1) : a;   // neg: add 1\nendmodule\n",[f"{w}-bit one's->two's complement."])
    emit(OUTC,f"signmag_to_twos{w}",
         f"module signmag_to_twos{w}(input [{w-1}:0] a, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    wire [{w-2}:0] mag = a[{w-2}:0];\n"
         f"    assign y = a[{w-1}] ? ((~{{1'b0,mag}}) + 1'b1) : {{1'b0,mag}};\nendmodule\n",[f"{w}-bit sign-magnitude->two's complement."])
    emit(OUTC,f"twos_to_signmag{w}",
         f"module twos_to_signmag{w}(input signed [{w-1}:0] a, output [{w-1}:0] y);\n"
         f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
         f"    wire [{w-1}:0] m = a[{w-1}] ? ((~a)+1'b1) : a;\n"
         f"    assign y = {{a[{w-1}], m[{w-2}:0]}};\nendmodule\n",[f"{w}-bit two's complement->sign-magnitude."])
    # thermometer
    L=[f"module bin_to_thermometer{w}(input [{int(math.ceil(math.log2(w+1)))-1}:0] n, output [{w-1}:0] y);"]
    L.append(f"    // define n input {COL['sel']}   // define y output {COL['out']}")
    for i in range(w):
        L.append(f"    assign y[{i}] = (n > {i});")
    L.append("endmodule")
    emit(OUTC,f"bin_to_thermometer{w}","\n".join(L)+"\n",[f"{w}-bit binary->thermometer code."])
    emit(OUTC,f"thermometer_to_bin{w}",
         f"module thermometer_to_bin{w}(input [{w-1}:0] a, output [{int(math.ceil(math.log2(w+1)))-1}:0] n);\n"
         f"    // define a input {COL['a']}   // define n output {COL['out']}\n"
         f"    assign n = {'+'.join(f'a[{i}]' for i in range(w))};\nendmodule\n",[f"{w}-bit thermometer->binary (popcount)."])
    emit(OUTC,f"thermometer_valid{w}",
         f"module thermometer_valid{w}(input [{w-1}:0] a, output valid);\n"
         f"    // define a input {COL['a']}   // define valid output {COL['status']}\n"
         f"    // valid thermometer = contiguous 1s from LSB: a[i] >= a[i+1]\n"
         f"    assign valid = &{{ {', '.join(f'(a[{i}] | ~a[{i+1}])' for i in range(w-1))} }};\nendmodule\n",[f"{w}-bit thermometer-code validity check."])

# excess/bias converters (specific)
emit(OUTC,"binary_to_excess3_digit",
     "module binary_to_excess3_digit(input [3:0] a, output [3:0] y);\n"
     "    // define a input 80.160.255   // define y output 120.255.160\n"
     "    assign y = a + 4'd3;\nendmodule\n",["BCD digit (0..9) -> excess-3 code."])
emit(OUTC,"excess3_to_binary_digit",
     "module excess3_to_binary_digit(input [3:0] a, output [3:0] y);\n"
     "    // define a input 80.160.255   // define y output 120.255.160\n"
     "    assign y = a - 4'd3;\nendmodule\n",["Excess-3 -> BCD digit."])
emit(OUTC,"binary_to_excess15_4",
     "module binary_to_excess15_4(input [3:0] a, output [4:0] y);\n"
     "    // define a input 80.160.255   // define y output 120.255.160\n"
     "    assign y = {1'b0,a} + 5'd15;\nendmodule\n",["4-bit value -> excess-15 (bias 15)."])
emit(OUTC,"excess15_to_binary4",
     "module excess15_to_binary4(input [4:0] a, output [3:0] y);\n"
     "    // define a input 80.160.255   // define y output 120.255.160\n"
     "    assign y = a - 5'd15;\nendmodule\n",["Excess-15 -> 4-bit value."])
emit(OUTC,"binary_to_excess127_8",
     "module binary_to_excess127_8(input [7:0] a, output [8:0] y);\n"
     "    // define a input 80.160.255   // define y output 120.255.160\n"
     "    assign y = {1'b0,a} + 9'd127;\nendmodule\n",["8-bit value -> excess-127 (float-exponent style bias)."])
emit(OUTC,"excess127_to_binary8",
     "module excess127_to_binary8(input [8:0] a, output [7:0] y);\n"
     "    // define a input 80.160.255   // define y output 120.255.160\n"
     "    assign y = a - 9'd127;\nendmodule\n",["Excess-127 -> 8-bit value."])

print("popcount + converters generated")
