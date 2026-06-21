import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, m_full_adder, m_half_adder
OUT=os.path.join(os.path.dirname(__file__),"..","src","demos")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")

# demo_half_adder: just the half adder exposed as a demo top
emit("demo_half_adder",
     "module demo_half_adder(input a, input b, output sum, output carry);\n"
     f"    // define a input {COL['a']}   // define b input {COL['b']}   // define sum output {COL['out']}   // define carry output {COL['flag']}\n"
     "    half_adder ha(.a(a),.b(b),.sum(sum),.carry(carry));\nendmodule\n\n"
     + m_half_adder(),
     ["Demo: a single half adder."])

# demo_full_adder
emit("demo_full_adder",
     "module demo_full_adder(input a, input b, input cin, output sum, output cout);\n"
     f"    // define a input {COL['a']}   // define b input {COL['b']}   // define cin input {COL['cin']}   // define sum output {COL['out']}   // define cout output {COL['flag']}\n"
     "    full_adder fa(.a(a),.b(b),.cin(cin),.sum(sum),.cout(cout));\nendmodule\n\n"
     + m_full_adder() + "\n" + m_half_adder(),
     ["Demo: a single full adder built from half adders."])

# demo_add_rc8: 8-bit ripple adder showcase
L=["module demo_add_rc8(input [7:0] a, input [7:0] b, input cin, output [7:0] sum, output cout);"]
L.append(f"    // define a input {COL['a']}   // define b input {COL['b']}   // define cin input {COL['cin']}   // define sum output {COL['out']}   // define cout output {COL['flag']}")
L.append("    wire [8:0] c; assign c[0]=cin;")
for i in range(8):
    L.append(f"    full_adder fa{i}(.a(a[{i}]),.b(b[{i}]),.cin(c[{i}]),.sum(sum[{i}]),.cout(c[{i+1}]));")
L.append("    assign cout=c[8];")
L.append("endmodule")
emit("demo_add_rc8", "\n".join(L)+"\n\n"+m_full_adder()+"\n"+m_half_adder(),
     ["Demo: 8-bit ripple-carry adder (8 chained full adders)."])

# demo_4bit_counter: 4-bit up counter with 7-seg-ready output
emit("demo_4bit_counter",
     "module demo_4bit_counter(input clk, input rst, output reg [3:0] count, output [6:0] seg);\n"
     f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define count output {COL['out']}   // define seg output {COL['out']}\n"
     "    always @(posedge clk) if (rst) count<=4'b0; else count<=count+1'b1;\n"
     "    reg [6:0] s;\n"
     "    always @(*) case(count)\n"
     "        4'h0:s=7'b0111111;4'h1:s=7'b0000110;4'h2:s=7'b1011011;4'h3:s=7'b1001111;\n"
     "        4'h4:s=7'b1100110;4'h5:s=7'b1101101;4'h6:s=7'b1111101;4'h7:s=7'b0000111;\n"
     "        4'h8:s=7'b1111111;4'h9:s=7'b1101111;4'ha:s=7'b1110111;4'hb:s=7'b1111100;\n"
     "        4'hc:s=7'b0111001;4'hd:s=7'b1011110;4'he:s=7'b1111001;4'hf:s=7'b1110001;\n"
     "    endcase\n    assign seg=s;\nendmodule\n",
     ["Demo: 4-bit counter driving a 7-segment display."])

# demo_alu8: 8-bit ALU showcase with flags
emit("demo_alu8",
     "module demo_alu8(input [7:0] a, input [7:0] b, input [2:0] op, output reg [7:0] y, output zero, output carry);\n"
     f"    // define a input {COL['a']}   // define b input {COL['b']}   // define op input {COL['sel']}   // define y output {COL['out']}   // define zero output {COL['status']}\n"
     "    reg [8:0] t;\n"
     "    always @(*) begin case(op)\n"
     "        3'b000: t={1'b0,a}+{1'b0,b};\n"
     "        3'b001: t={1'b0,a}-{1'b0,b};\n"
     "        3'b010: t={1'b0,(a&b)};\n"
     "        3'b011: t={1'b0,(a|b)};\n"
     "        3'b100: t={1'b0,(a^b)};\n"
     "        3'b101: t={1'b0,(~a)};\n"
     "        3'b110: t={1'b0,a}<<1;\n"
     "        3'b111: t={1'b0,a}>>1;\n"
     "    endcase y=t[7:0]; end\n"
     "    assign zero=(y==8'b0); assign carry=t[8];\nendmodule\n",
     ["Demo: 8-bit ALU with zero and carry flags."])

# demo_traffic_light: classic FSM
emit("demo_traffic_light",
     "module demo_traffic_light(input clk, input rst, output reg [2:0] lights);\n"
     f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define lights output {COL['out']}\n"
     "    // lights = {red, yellow, green}\n"
     "    reg [1:0] state; reg [3:0] timer;\n"
     "    localparam GREEN=0, YELLOW=1, RED=2;\n"
     "    always @(posedge clk) begin\n"
     "        if (rst) begin state<=GREEN; timer<=0; end\n"
     "        else begin timer<=timer+1'b1;\n"
     "            case (state)\n"
     "                GREEN:  if (timer==4'd9) begin state<=YELLOW; timer<=0; end\n"
     "                YELLOW: if (timer==4'd3) begin state<=RED;    timer<=0; end\n"
     "                RED:    if (timer==4'd9) begin state<=GREEN;  timer<=0; end\n"
     "            endcase\n"
     "        end\n"
     "    end\n"
     "    always @(*) case(state)\n"
     "        GREEN:  lights=3'b001;\n"
     "        YELLOW: lights=3'b010;\n"
     "        RED:    lights=3'b100;\n"
     "        default:lights=3'b100;\n"
     "    endcase\nendmodule\n",
     ["Demo: traffic-light FSM (green/yellow/red)."])

# demo_seven_seg_driver: hex value to 7seg
emit("demo_seven_seg_driver",
     "module demo_seven_seg_driver(input [3:0] value, input dp, output [7:0] seg);\n"
     f"    // define value input {COL['a']}   // define dp input {COL['cin']}   // define seg output {COL['out']}\n"
     "    reg [6:0] base;\n"
     "    always @(*) case(value)\n"
     "        4'h0:base=7'b0111111;4'h1:base=7'b0000110;4'h2:base=7'b1011011;4'h3:base=7'b1001111;\n"
     "        4'h4:base=7'b1100110;4'h5:base=7'b1101101;4'h6:base=7'b1111101;4'h7:base=7'b0000111;\n"
     "        4'h8:base=7'b1111111;4'h9:base=7'b1101111;4'ha:base=7'b1110111;4'hb:base=7'b1111100;\n"
     "        4'hc:base=7'b0111001;4'hd:base=7'b1011110;4'he:base=7'b1111001;4'hf:base=7'b1110001;\n"
     "    endcase\n    assign seg={dp,base};\nendmodule\n",
     ["Demo: hex-to-7-segment driver with decimal point."])

# demo_simple_cpu4: a tiny 4-bit accumulator CPU (educational)
emit("demo_simple_cpu4",
     "module demo_simple_cpu4(input clk, input rst, input [7:0] instr, output [3:0] acc_out, output zero);\n"
     f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define instr input {COL['a']}   // define acc_out output {COL['out']}   // define zero output {COL['status']}\n"
     "    // instr = {opcode[3:0], operand[3:0]}\n"
     "    // opcodes: 0 LOAD, 1 ADD, 2 SUB, 3 AND, 4 OR, 5 XOR, 6 SHL, 7 SHR\n"
     "    reg [3:0] acc;\n"
     "    wire [3:0] opcode = instr[7:4];\n"
     "    wire [3:0] operand = instr[3:0];\n"
     "    reg [3:0] next;\n"
     "    always @(*) begin case(opcode)\n"
     "        4'd0: next=operand;\n"
     "        4'd1: next=acc+operand;\n"
     "        4'd2: next=acc-operand;\n"
     "        4'd3: next=acc&operand;\n"
     "        4'd4: next=acc|operand;\n"
     "        4'd5: next=acc^operand;\n"
     "        4'd6: next=acc<<1;\n"
     "        4'd7: next=acc>>1;\n"
     "        default: next=acc;\n"
     "    endcase end\n"
     "    always @(posedge clk) if (rst) acc<=4'b0; else acc<=next;\n"
     "    assign acc_out=acc; assign zero=(acc==4'b0);\nendmodule\n",
     ["Demo: tiny 4-bit accumulator CPU (8 ops)."])

# demo_stopwatch: BCD seconds counter
emit("demo_stopwatch",
     "module demo_stopwatch(input clk, input rst, input tick, output reg [3:0] ones, output reg [3:0] tens);\n"
     f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define tick input {COL['en']}   // define ones output {COL['out']}   // define tens output {COL['out']}\n"
     "    // Two-digit BCD seconds counter (0-59), advances on tick.\n"
     "    always @(posedge clk) begin\n"
     "        if (rst) begin ones<=0; tens<=0; end\n"
     "        else if (tick) begin\n"
     "            if (ones==4'd9) begin ones<=0;\n"
     "                if (tens==4'd5) tens<=0; else tens<=tens+1'b1;\n"
     "            end else ones<=ones+1'b1;\n"
     "        end\n"
     "    end\nendmodule\n",
     ["Demo: 2-digit BCD stopwatch (0-59 seconds)."])

# demo_dice_roller: LFSR-based 1-6 generator
emit("demo_dice_roller",
     "module demo_dice_roller(input clk, input rst, input roll, output reg [2:0] face);\n"
     f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define roll input {COL['en']}   // define face output {COL['out']}\n"
     "    reg [3:0] lfsr;\n"
     "    wire fb = lfsr[3]^lfsr[2];\n"
     "    always @(posedge clk) begin\n"
     "        if (rst) begin lfsr<=4'b1; face<=3'd1; end\n"
     "        else begin lfsr<={lfsr[2:0],fb};\n"
     "            if (roll) begin\n"
     "                // map 4-bit lfsr to 1..6\n"
     "                if (lfsr[2:0]==3'd0 || lfsr[2:0] > 3'd6) face<=3'd1; else face<=lfsr[2:0];\n"
     "            end\n"
     "        end\n"
     "    end\nendmodule\n",
     ["Demo: LFSR-based dice roller (faces 1-6)."])

print("demos generated")
