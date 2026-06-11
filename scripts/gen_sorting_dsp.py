import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS
import _structural as S
OUTS=os.path.join(os.path.dirname(__file__),"..","src","sorting")
OUTD=os.path.join(os.path.dirname(__file__),"..","src","dsp")
def emits(name,body,desc): write(os.path.join(OUTS,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")
def emitd(name,body,desc): write(os.path.join(OUTD,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")

# ---- compare/swap & primitives ---------------------------------------
for w in WIDTHS:
    emits(f"min2_{w}",
          f"module min2_{w}(input [{w-1}:0] a, input [{w-1}:0] b, output [{w-1}:0] y);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define y output {COL['out']}\n"
          f"    assign y = (a < b) ? a : b;\nendmodule\n",[f"{w}-bit 2-input minimum."])
    emits(f"max2_{w}",
          f"module max2_{w}(input [{w-1}:0] a, input [{w-1}:0] b, output [{w-1}:0] y);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define y output {COL['out']}\n"
          f"    assign y = (a > b) ? a : b;\nendmodule\n",[f"{w}-bit 2-input maximum."])
    emits(f"compare_swap{w}",
          f"module compare_swap{w}(input [{w-1}:0] a, input [{w-1}:0] b, output [{w-1}:0] lo, output [{w-1}:0] hi);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define lo output {COL['out']}   // define hi output {COL['out']}\n"
          f"    assign lo = (a < b) ? a : b;\n    assign hi = (a < b) ? b : a;\nendmodule\n",
          [f"{w}-bit compare-and-swap cell (sorting primitive)."])
    emits(f"median3_{w}",
          f"module median3_{w}(input [{w-1}:0] a, input [{w-1}:0] b, input [{w-1}:0] c, output [{w-1}:0] med);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define c input {COL['b']}   // define med output {COL['out']}\n"
          f"    wire [{w-1}:0] mx = (a>b)?a:b;\n"
          f"    wire [{w-1}:0] mn = (a<b)?a:b;\n"
          f"    assign med = (c>mx)?mx : (c<mn)?mn : c;\nendmodule\n",[f"{w}-bit median-of-3."])

# ---- sort4 / sort8 (sorting networks of compare_swap) ----------------
def sort_network(n, w):
    """Batcher odd-even style network via behavioral compare-swap chain (named)."""
    # use a known optimal network for small n
    NETS={4:[(0,1),(2,3),(0,2),(1,3),(1,2)],
          8:[(0,1),(2,3),(4,5),(6,7),(0,2),(1,3),(4,6),(5,7),(1,2),(5,6),(0,4),(3,7),(1,5),(2,6),(1,4),(3,6),(2,4),(3,5),(3,4)]}
    net=NETS[n]
    ins=", ".join(f"input [{w-1}:0] in{i}" for i in range(n))
    outs=", ".join(f"output [{w-1}:0] out{i}" for i in range(n))
    L=[f"module sort{n}_{w}({ins}, {outs});"]
    L.append(f"    // define out0 output {COL['out']}")
    # use wire arrays for stages
    L.append(f"    wire [{w-1}:0] s [0:{n-1}];")
    for i in range(n):
        L.append(f"    assign s[{i}] = in{i};")
    # We need sequential reassignment; use a chain of intermediate arrays
    cur=[f"in{i}" for i in range(n)]
    stage=0
    decl=[]
    body=[]
    arr=[f"in{i}" for i in range(n)]
    # generate fresh wires per comparator output
    namecount=0
    def newwire():
        nonlocal namecount
        nm=f"w{namecount}"; namecount+=1; return nm
    for (i,j) in net:
        lo=newwire(); hi=newwire()
        decl.append(f"    wire [{w-1}:0] {lo}, {hi};")
        body.append(f"    assign {lo} = ({arr[i]} < {arr[j]}) ? {arr[i]} : {arr[j]};")
        body.append(f"    assign {hi} = ({arr[i]} < {arr[j]}) ? {arr[j]} : {arr[i]};")
        arr[i]=lo; arr[j]=hi
    L=[f"module sort{n}_{w}({ins}, {outs});"]
    L.append(f"    // define out0 output {COL['out']}")
    L += decl + body
    for i in range(n):
        L.append(f"    assign out{i} = {arr[i]};")
    L.append("endmodule")
    return "\n".join(L)+"\n"
for w in [4,8]:
    emits(f"sort4_{w}", sort_network(4,w), [f"4-input sorting network ({w}-bit, ascending)."])
    emits(f"sort8_{w}", sort_network(8,w), [f"8-input sorting network ({w}-bit, ascending)."])

# ---- bitonic sorters (named, compare-swap based) ---------------------
def bitonic(n, w):
    # bitonic network generation
    comparators=[]
    def addcs(i,j,direction):
        comparators.append((i,j,direction))
    def bitonic_merge(lo, cnt, direction):
        if cnt>1:
            k=cnt//2
            for i in range(lo, lo+k):
                addcs(i, i+k, direction)
            bitonic_merge(lo, k, direction)
            bitonic_merge(lo+k, k, direction)
    def bitonic_sort(lo, cnt, direction):
        if cnt>1:
            k=cnt//2
            bitonic_sort(lo, k, 1)
            bitonic_sort(lo+k, k, 0)
            bitonic_merge(lo, cnt, direction)
    bitonic_sort(0, n, 1)
    ins=", ".join(f"input [{w-1}:0] in{i}" for i in range(n))
    outs=", ".join(f"output [{w-1}:0] out{i}" for i in range(n))
    arr=[f"in{i}" for i in range(n)]
    decl=[]; body=[]; nc=0
    for (i,j,d) in comparators:
        a=f"b{nc}"; b=f"b{nc+1}"; nc+=2
        decl.append(f"    wire [{w-1}:0] {a}, {b};")
        if d==1: # ascending: lo->i, hi->j
            body.append(f"    assign {a} = ({arr[i]} < {arr[j]}) ? {arr[i]} : {arr[j]};")
            body.append(f"    assign {b} = ({arr[i]} < {arr[j]}) ? {arr[j]} : {arr[i]};")
        else:
            body.append(f"    assign {a} = ({arr[i]} > {arr[j]}) ? {arr[i]} : {arr[j]};")
            body.append(f"    assign {b} = ({arr[i]} > {arr[j]}) ? {arr[j]} : {arr[i]};")
        arr[i]=a; arr[j]=b
    L=[f"module bitonic_sort{n}_{w}({ins}, {outs});"]
    L.append(f"    // define out0 output {COL['out']}")
    L += decl + body
    for i in range(n):
        L.append(f"    assign out{i} = {arr[i]};")
    L.append("endmodule")
    return "\n".join(L)+"\n"
for n in [4,8,16]:
    emits(f"bitonic_sort{n}_8", bitonic(n,8), [f"{n}-input bitonic sorting network (8-bit)."])

# ---- §22 DSP fixed-point ---------------------------------------------
# Q-format add/sub/mul (Q8.8 for 16-bit, Q4.4 for 8-bit, etc.)
QFMT={8:(4,4),16:(8,8),32:(16,16)}
for w,(qi,qf) in QFMT.items():
    emitd(f"fixed_add_q{qi}_{qf}",
          f"module fixed_add_q{qi}_{qf}(input signed [{w-1}:0] a, input signed [{w-1}:0] b, output signed [{w-1}:0] y, output ovf);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define y output {COL['out']}\n"
          f"    wire signed [{w}:0] s = a + b;\n"
          f"    assign y = s[{w-1}:0];\n"
          f"    assign ovf = (a[{w-1}]==b[{w-1}]) && (y[{w-1}]!=a[{w-1}]);\nendmodule\n",
          [f"Q{qi}.{qf} fixed-point add ({w}-bit)."])
    emitd(f"fixed_sub_q{qi}_{qf}",
          f"module fixed_sub_q{qi}_{qf}(input signed [{w-1}:0] a, input signed [{w-1}:0] b, output signed [{w-1}:0] y, output ovf);\n"
          f"    // define a input {COL['a']}   // define b input {COL['b']}   // define y output {COL['out']}\n"
          f"    wire signed [{w}:0] s = a - b;\n"
          f"    assign y = s[{w-1}:0];\n"
          f"    assign ovf = (a[{w-1}]!=b[{w-1}]) && (y[{w-1}]!=a[{w-1}]);\nendmodule\n",
          [f"Q{qi}.{qf} fixed-point subtract ({w}-bit)."])
    # structural signed fixed-point multiply: full = a*b via structural signed
    # multiplier (no *), then arithmetic right shift by qf to rescale.
    _fmtop=f"fixed_mul_q{qi}_{qf}"
    _W=w; _P=2*w
    _L=[f"module {_fmtop}(input signed [{w-1}:0] a, input signed [{w-1}:0] b, output signed [{w-1}:0] y);"]
    _L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define y output {COL['out']}")
    _L.append(f"    wire signed [{_P-1}:0] full;")
    _L.append(f"    fmsmul{w} mm(.a(a),.b(b),.product(full));")
    _L.append(f"    assign y = full >>> {qf};   // rescale by fractional bits (arith shift)")
    _L.append("endmodule")
    _body="\n".join(_L)+"\n\n"+S.signed_multiplier_file(w, f"fmsmul{w}", core="array")
    emitd(_fmtop, _body, [f"Q{qi}.{qf} fixed-point multiply ({w}-bit, rescaled).","Structural signed multiply + arithmetic shift; no * operator."])
    emitd(f"fixed_round_q{qi}_{qf}",
          f"module fixed_round_q{qi}_{qf}(input signed [{w-1}:0] a, output signed [{qi}:0] y);\n"
          f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
          f"    // round to integer: add 0.5 (1<<(qf-1)) then truncate fractional bits\n"
          f"    wire signed [{w-1}:0] r = a + {w}'sd{1<<(qf-1)};\n"
          f"    assign y = r >>> {qf};\nendmodule\n",
          [f"Q{qi}.{qf} round-to-nearest integer."])
    emitd(f"fixed_saturate_q{qi}_{qf}",
          f"module fixed_saturate_q{qi}_{qf}(input signed [{w+3}:0] a, output signed [{w-1}:0] y);\n"
          f"    // define a input {COL['a']}   // define y output {COL['out']}\n"
          f"    wire signed [{w-1}:0] maxv = {{1'b0,{{{w-1}{{1'b1}}}}}};\n"
          f"    wire signed [{w-1}:0] minv = {{1'b1,{{{w-1}{{1'b0}}}}}};\n"
          f"    assign y = (a > maxv) ? maxv : (a < minv) ? minv : a[{w-1}:0];\nendmodule\n",
          [f"Q{qi}.{qf} saturate wide accumulator to {w}-bit."])

# FIR filter (4-tap, fixed coefficients) and CORDIC stub
emitd("fir4_q8_8",
      "module fir4_q8_8(input clk, input rst, input signed [15:0] x, output reg signed [15:0] y);\n"
      "    // define clk input 255.230.80   // define x input 80.160.255   // define y output 120.255.160\n"
      "    // 4-tap FIR, Q8.8 coefficients all 0.25 (=64 in Q8.8) -> moving average.\n"
      "    // coefficient multiply by 64 is a structural left-shift by 6 (no * operator).\n"
      "    reg signed [15:0] d0,d1,d2,d3;\n"
      "    wire signed [31:0] xx = $signed({{16{x[15]}},  x})  << 6;\n"
      "    wire signed [31:0] t0 = $signed({{16{d0[15]}}, d0}) << 6;\n"
      "    wire signed [31:0] t1 = $signed({{16{d1[15]}}, d1}) << 6;\n"
      "    wire signed [31:0] t2 = $signed({{16{d2[15]}}, d2}) << 6;\n"
      "    wire signed [31:0] acc = xx + t0 + t1 + t2;\n"
      "    always @(posedge clk) begin\n"
      "        if (rst) begin d0<=0;d1<=0;d2<=0;d3<=0;y<=0; end\n"
      "        else begin d0<=x; d1<=d0; d2<=d1; d3<=d2; y<=acc>>>8; end\n"
      "    end\nendmodule\n",
      ["4-tap FIR moving-average filter (Q8.8); coefficient multiply is a shift, no * operator."])
emitd("cordic_rotate16",
      "module cordic_rotate16(input clk, input rst, input start, input signed [15:0] x0, input signed [15:0] y0, input signed [15:0] angle,\n"
      "    output reg signed [15:0] x_out, output reg signed [15:0] y_out, output reg done);\n"
      "    // define clk input 255.230.80   // define rst input 255.80.80   // define start input 255.180.80\n"
      "    // Iterative CORDIC rotation mode (16-bit, 12 iterations).\n"
      "    reg signed [15:0] x, y, z; reg [3:0] i; reg busy;\n"
      "    reg signed [15:0] atan [0:11];\n"
      "    initial begin\n"
      "        atan[0]=16'sd12867; atan[1]=16'sd7596; atan[2]=16'sd4014; atan[3]=16'sd2037;\n"
      "        atan[4]=16'sd1023;  atan[5]=16'sd512;  atan[6]=16'sd256;  atan[7]=16'sd128;\n"
      "        atan[8]=16'sd64;    atan[9]=16'sd32;   atan[10]=16'sd16;  atan[11]=16'sd8;\n"
      "    end\n"
      "    always @(posedge clk) begin\n"
      "        if (rst) begin busy<=0; done<=0; end\n"
      "        else if (start) begin x<=x0; y<=y0; z<=angle; i<=0; busy<=1; done<=0; end\n"
      "        else if (busy) begin\n"
      "            if (i==12) begin busy<=0; done<=1; x_out<=x; y_out<=y; end\n"
      "            else begin\n"
      "                if (z[15]==1'b0) begin x<=x-(y>>>i); y<=y+(x>>>i); z<=z-atan[i]; end\n"
      "                else begin x<=x+(y>>>i); y<=y-(x>>>i); z<=z+atan[i]; end\n"
      "                i<=i+1;\n"
      "            end\n"
      "        end else done<=0;\n"
      "    end\nendmodule\n",
      ["16-bit iterative CORDIC rotator (12 iterations)."])

print("sorting + dsp generated")
