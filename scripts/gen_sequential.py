import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL
OUT=os.path.join(os.path.dirname(__file__),"..","src","sequential")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")
CLK=f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define en input {COL['en']}\n"

# latches
emit("sr_latch_nor",
     "module sr_latch_nor(input s, input r, output q, output qn);\n"
     "    // define s input 80.160.255   // define r input 255.80.80   // define q output 120.255.160\n"
     "    assign q  = ~(r | qn);\n    assign qn = ~(s | q);\nendmodule\n",["SR latch (cross-coupled NOR)."])
emit("sr_latch_nand",
     "module sr_latch_nand(input s, input r, output q, output qn);\n"
     "    // define s input 80.160.255   // define r input 255.80.80   // define q output 120.255.160\n"
     "    assign q  = ~(s & qn);\n    assign qn = ~(r & q);\nendmodule\n",["SR latch (cross-coupled NAND, active-low)."])
emit("gated_sr_latch",
     "module gated_sr_latch(input s, input r, input en, output reg q);\n"
     "    // define en input 255.180.80\n"
     "    always @(*) if (en) begin if (s & ~r) q=1'b1; else if (r & ~s) q=1'b0; end\nendmodule\n",["Gated SR latch (level-sensitive)."])
emit("d_latch",
     "module d_latch(input d, input en, output reg q);\n"
     "    // define d input 80.160.255   // define en input 255.180.80   // define q output 120.255.160\n"
     "    always @(*) if (en) q = d;\nendmodule\n",["D latch (transparent when en=1)."])
emit("d_latch_en","module d_latch_en(input d, input en, output reg q);\n"
     "    always @(*) if (en) q = d;\nendmodule\n",["D latch with explicit enable."])
emit("jk_latch",
     "module jk_latch(input j, input k, input en, output reg q);\n"
     "    always @(*) if (en) case ({j,k}) 2'b01:q=1'b0; 2'b10:q=1'b1; 2'b11:q=~q; default:; endcase\nendmodule\n",["JK latch."])
emit("t_latch",
     "module t_latch(input t, input en, output reg q);\n"
     "    always @(*) if (en && t) q=~q;\nendmodule\n",["T (toggle) latch."])

# flip-flops
emit("dff_posedge",
     "module dff_posedge(input clk, input d, output reg q);\n"
     f"    // define clk input {COL['clk']}   // define d input {COL['a']}   // define q output {COL['out']}\n"
     "    always @(posedge clk) q <= d;\nendmodule\n",["Positive-edge D flip-flop."])
emit("dff_negedge",
     "module dff_negedge(input clk, input d, output reg q);\n"
     "    always @(negedge clk) q <= d;\nendmodule\n",["Negative-edge D flip-flop."])
emit("dff_en",
     "module dff_en(input clk, input en, input d, output reg q);\n"
     "    always @(posedge clk) if (en) q <= d;\nendmodule\n",["D flip-flop with enable."])
emit("dff_reset_sync",
     "module dff_reset_sync(input clk, input rst, input d, output reg q);\n"
     f"{CLK}"
     "    always @(posedge clk) if (rst) q <= 1'b0; else q <= d;\nendmodule\n",["D flip-flop, synchronous reset."])
emit("dff_reset_async",
     "module dff_reset_async(input clk, input rst, input d, output reg q);\n"
     "    always @(posedge clk or posedge rst) if (rst) q <= 1'b0; else q <= d;\nendmodule\n",["D flip-flop, asynchronous reset."])
emit("dff_set_reset",
     "module dff_set_reset(input clk, input s, input r, input d, output reg q);\n"
     "    always @(posedge clk) if (r) q<=1'b0; else if (s) q<=1'b1; else q<=d;\nendmodule\n",["D flip-flop with sync set & reset."])
emit("jkff",
     "module jkff(input clk, input j, input k, output reg q);\n"
     "    always @(posedge clk) case({j,k}) 2'b01:q<=0;2'b10:q<=1;2'b11:q<=~q;default:; endcase\nendmodule\n",["JK flip-flop."])
emit("tff",
     "module tff(input clk, input t, output reg q);\n"
     "    always @(posedge clk) if (t) q<=~q;\nendmodule\n",["T (toggle) flip-flop."])

# registers reg{4,8,12,16,20,32,40} + _en + _reset
for w in [4,8,12,16,20,32,40]:
    emit(f"reg{w}",
         f"module reg{w}(input clk, input [{w-1}:0] d, output reg [{w-1}:0] q);\n"
         f"    // define clk input {COL['clk']}   // define d input {COL['a']}   // define q output {COL['out']}\n"
         f"    always @(posedge clk) q <= d;\nendmodule\n",[f"{w}-bit register."])
    emit(f"reg_en{w}",
         f"module reg_en{w}(input clk, input en, input [{w-1}:0] d, output reg [{w-1}:0] q);\n"
         f"    // define clk input {COL['clk']}   // define en input {COL['en']}   // define d input {COL['a']}   // define q output {COL['out']}\n"
         f"    always @(posedge clk) if (en) q <= d;\nendmodule\n",[f"{w}-bit register with enable."])
    emit(f"reg_reset{w}",
         f"module reg_reset{w}(input clk, input rst, input en, input [{w-1}:0] d, output reg [{w-1}:0] q);\n"
         f"{CLK}    // define d input {COL['a']}   // define q output {COL['out']}\n"
         f"    always @(posedge clk) if (rst) q <= {w}'b0; else if (en) q <= d;\nendmodule\n",[f"{w}-bit register, sync reset + enable."])

# shift registers
for w in [4,8,16,32]:
    emit(f"siso{w}",
         f"module siso{w}(input clk, input sin, output sout);\n"
         f"    // define clk input {COL['clk']}   // define sin input {COL['a']}   // define sout output {COL['out']}\n"
         f"    reg [{w-1}:0] sr;\n    always @(posedge clk) sr <= {{sr[{w-2}:0], sin}};\n    assign sout = sr[{w-1}];\nendmodule\n",
         [f"{w}-bit serial-in serial-out shift register."])
    emit(f"sipo{w}",
         f"module sipo{w}(input clk, input sin, output [{w-1}:0] q);\n"
         f"    // define clk input {COL['clk']}   // define sin input {COL['a']}   // define q output {COL['out']}\n"
         f"    reg [{w-1}:0] sr;\n    always @(posedge clk) sr <= {{sr[{w-2}:0], sin}};\n    assign q = sr;\nendmodule\n",
         [f"{w}-bit serial-in parallel-out shift register."])
    emit(f"piso{w}",
         f"module piso{w}(input clk, input load, input [{w-1}:0] d, output sout);\n"
         f"    // define clk input {COL['clk']}   // define load input {COL['en']}   // define d input {COL['a']}   // define sout output {COL['out']}\n"
         f"    reg [{w-1}:0] sr;\n    always @(posedge clk) if (load) sr <= d; else sr <= {{1'b0, sr[{w-1}:1]}};\n    assign sout = sr[0];\nendmodule\n",
         [f"{w}-bit parallel-in serial-out shift register."])
    emit(f"pipo{w}",
         f"module pipo{w}(input clk, input en, input [{w-1}:0] d, output reg [{w-1}:0] q);\n"
         f"    // define clk input {COL['clk']}   // define en input {COL['en']}   // define d input {COL['a']}   // define q output {COL['out']}\n"
         f"    always @(posedge clk) if (en) q <= d;\nendmodule\n",[f"{w}-bit parallel-in parallel-out register."])
    emit(f"universal_shift_reg{w}",
         f"module universal_shift_reg{w}(input clk, input [1:0] mode, input sl_in, input sr_in, input [{w-1}:0] d, output reg [{w-1}:0] q);\n"
         f"    // define clk input {COL['clk']}   // define mode input {COL['sel']}   // define d input {COL['a']}   // define q output {COL['out']}\n"
         f"    // mode: 00 hold, 01 shift-right, 10 shift-left, 11 parallel-load\n"
         f"    always @(posedge clk) case (mode)\n"
         f"        2'b01: q <= {{sr_in, q[{w-1}:1]}};\n"
         f"        2'b10: q <= {{q[{w-2}:0], sl_in}};\n"
         f"        2'b11: q <= d;\n"
         f"        default: q <= q;\n    endcase\nendmodule\n",[f"{w}-bit universal shift register (hold/L/R/load)."])

print("sequential generated")
