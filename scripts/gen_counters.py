import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL
OUT=os.path.join(os.path.dirname(__file__),"..","src","counters")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")
CLK=f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define en input {COL['en']}\n"

for w in [4,8,16,32]:
    emit(f"counter_up{w}",
         f"module counter_up{w}(input clk, input rst, input en, output reg [{w-1}:0] q);\n"
         f"{CLK}    // define q output {COL['out']}\n"
         f"    always @(posedge clk) if (rst) q<={w}'b0; else if (en) q<=q+1'b1;\nendmodule\n",[f"{w}-bit up counter."])
    emit(f"counter_down{w}",
         f"module counter_down{w}(input clk, input rst, input en, output reg [{w-1}:0] q);\n"
         f"{CLK}    // define q output {COL['out']}\n"
         f"    always @(posedge clk) if (rst) q<={{{w}{{1'b1}}}}; else if (en) q<=q-1'b1;\nendmodule\n",[f"{w}-bit down counter."])
    emit(f"counter_updown{w}",
         f"module counter_updown{w}(input clk, input rst, input en, input up, output reg [{w-1}:0] q);\n"
         f"{CLK}    // define up input {COL['sel']}   // define q output {COL['out']}\n"
         f"    always @(posedge clk) if (rst) q<={w}'b0; else if (en) q<= up ? q+1'b1 : q-1'b1;\nendmodule\n",[f"{w}-bit up/down counter."])
    emit(f"ring_counter{w}",
         f"module ring_counter{w}(input clk, input rst, output reg [{w-1}:0] q);\n"
         f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define q output {COL['out']}\n"
         f"    always @(posedge clk) if (rst) q<={{{{{w-1}{{1'b0}}}},1'b1}}; else q<={{q[{w-2}:0],q[{w-1}]}};\nendmodule\n",[f"{w}-bit ring counter (one-hot rotate)."])
    emit(f"johnson_counter{w}",
         f"module johnson_counter{w}(input clk, input rst, output reg [{w-1}:0] q);\n"
         f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define q output {COL['out']}\n"
         f"    always @(posedge clk) if (rst) q<={w}'b0; else q<={{q[{w-2}:0], ~q[{w-1}]}};\nendmodule\n",[f"{w}-bit Johnson (twisted-ring) counter."])
    emit(f"gray_counter{w}",
         f"module gray_counter{w}(input clk, input rst, input en, output [{w-1}:0] gray);\n"
         f"{CLK}    // define gray output {COL['out']}\n"
         f"    reg [{w-1}:0] bin;\n"
         f"    always @(posedge clk) if (rst) bin<={w}'b0; else if (en) bin<=bin+1'b1;\n"
         f"    assign gray = bin ^ (bin >> 1);\nendmodule\n",[f"{w}-bit Gray-code counter."])

# mod-N counters
for N in [3,5,6,10,12,16,60]:
    w=max(1,int(math.ceil(math.log2(N))))
    emit(f"mod{N}_counter",
         f"module mod{N}_counter(input clk, input rst, input en, output reg [{w-1}:0] q, output tc);\n"
         f"{CLK}    // define q output {COL['out']}   // define tc output {COL['status']}\n"
         f"    assign tc = (q == {N-1});\n"
         f"    always @(posedge clk) if (rst) q<={w}'b0; else if (en) q <= tc ? {w}'b0 : q+1'b1;\nendmodule\n",[f"Modulo-{N} counter (0..{N-1}), tc at terminal count."])

# LFSRs (maximal-length taps)
TAPS={4:[4,3],8:[8,6,5,4],16:[16,15,13,4],32:[32,22,2,1]}
for w in [4,8,16,32]:
    taps=TAPS[w]
    fb=" ^ ".join(f"q[{t-1}]" for t in taps)
    emit(f"lfsr{w}",
         f"module lfsr{w}(input clk, input rst, input en, output reg [{w-1}:0] q);\n"
         f"{CLK}    // define q output {COL['out']}\n"
         f"    wire fb = {fb};\n"
         f"    always @(posedge clk) if (rst) q<={w}'b1; else if (en) q<={{q[{w-2}:0], fb}};\nendmodule\n",[f"{w}-bit Fibonacci LFSR (maximal-length taps)."])
    emit(f"fibonacci_lfsr{w}",
         f"module fibonacci_lfsr{w}(input clk, input rst, input en, output reg [{w-1}:0] q);\n"
         f"{CLK}    // define q output {COL['out']}\n"
         f"    wire fb = {fb};\n"
         f"    always @(posedge clk) if (rst) q<={w}'b1; else if (en) q<={{q[{w-2}:0], fb}};\nendmodule\n",[f"{w}-bit Fibonacci LFSR."])
    # Galois form
    polymask=0
    for t in taps[1:]:
        polymask |= (1<<(t-1))
    emit(f"galois_lfsr{w}",
         f"module galois_lfsr{w}(input clk, input rst, input en, output reg [{w-1}:0] q);\n"
         f"{CLK}    // define q output {COL['out']}\n"
         f"    wire lsb = q[0];\n"
         f"    always @(posedge clk) if (rst) q<={w}'b1; else if (en) q <= (q >> 1) ^ ({{{w}{{lsb}}}} & {w}'h{polymask:x});\nendmodule\n",[f"{w}-bit Galois LFSR."])

# timers, clock dividers, pwm
for w in [4,8,16,32]:
    emit(f"timer{w}",
         f"module timer{w}(input clk, input rst, input en, input [{w-1}:0] period, output reg [{w-1}:0] count, output expired);\n"
         f"{CLK}    // define period input {COL['a']}   // define count output {COL['out']}   // define expired output {COL['status']}\n"
         f"    assign expired = (count == period);\n"
         f"    always @(posedge clk) if (rst) count<={w}'b0; else if (en) count <= expired ? {w}'b0 : count+1'b1;\nendmodule\n",[f"{w}-bit programmable timer."])
    emit(f"pwm{w}",
         f"module pwm{w}(input clk, input rst, input [{w-1}:0] duty, output pwm_out);\n"
         f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define duty input {COL['a']}   // define pwm_out output {COL['out']}\n"
         f"    reg [{w-1}:0] cnt;\n"
         f"    always @(posedge clk) if (rst) cnt<={w}'b0; else cnt<=cnt+1'b1;\n"
         f"    assign pwm_out = (cnt < duty);\nendmodule\n",[f"{w}-bit PWM generator (duty/2^{w})."])
for d in [2,4,8,16,32]:
    bits=int(math.log2(d))
    emit(f"clock_divider{d}",
         f"module clock_divider{d}(input clk, input rst, output clk_out);\n"
         f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define clk_out output {COL['out']}\n"
         f"    reg [{bits-1 if bits>0 else 0}:0] cnt;\n"
         f"    always @(posedge clk) if (rst) cnt<=0; else cnt<=cnt+1'b1;\n"
         f"    assign clk_out = cnt[{bits-1}];\nendmodule\n",[f"Clock divider by {d}."])

# misc
emit("one_pulse",
     "module one_pulse(input clk, input rst, input trig, output reg pulse);\n"
     "    reg seen;\n    always @(posedge clk) begin if (rst) begin seen<=0; pulse<=0; end\n"
     "        else begin pulse <= trig & ~seen; seen <= trig; end end\nendmodule\n",["Single-cycle pulse on rising trigger."])
emit("edge_detector_rising",
     "module edge_detector_rising(input clk, input a, output rise);\n"
     "    reg p;\n    always @(posedge clk) p<=a;\n    assign rise = a & ~p;\nendmodule\n",["Rising-edge detector."])
emit("edge_detector_falling",
     "module edge_detector_falling(input clk, input a, output fall);\n"
     "    reg p;\n    always @(posedge clk) p<=a;\n    assign fall = ~a & p;\nendmodule\n",["Falling-edge detector."])
emit("edge_detector_both",
     "module edge_detector_both(input clk, input a, output edge_any);\n"
     "    reg p;\n    always @(posedge clk) p<=a;\n    assign edge_any = a ^ p;\nendmodule\n",["Any-edge detector."])
emit("debouncer",
     "module debouncer(input clk, input rst, input noisy, output reg clean);\n"
     "    reg [15:0] cnt;\n    always @(posedge clk) begin\n"
     "        if (rst) begin cnt<=0; clean<=0; end\n"
     "        else if (noisy==clean) cnt<=0;\n"
     "        else begin cnt<=cnt+1'b1; if (&cnt) clean<=noisy; end\n    end\nendmodule\n",["Switch debouncer (counter-based)."])

print("counters generated")
