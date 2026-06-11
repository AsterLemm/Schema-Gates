import os, sys, math
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write, COL, WIDTHS
OUT=os.path.join(os.path.dirname(__file__),"..","src","alu_datapath")
def emit(name,body,desc): write(os.path.join(OUT,name+".v"),banner(name+".v",desc)+"\n"+body+"\n")

for w in WIDTHS:
    m1=w-1
    sb=max(1,int(math.ceil(math.log2(w))))
    # logic-only ALU
    emit(f"alu_logic{w}",
         f"module alu_logic{w}(input [{m1}:0] a, input [{m1}:0] b, input [1:0] op, output reg [{m1}:0] y);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define op input {COL['sel']}   // define y output {COL['out']}\n"
         f"    // op: 00 AND, 01 OR, 10 XOR, 11 NOT a\n"
         f"    always @(*) case(op) 2'b00:y=a&b; 2'b01:y=a|b; 2'b10:y=a^b; 2'b11:y=~a; endcase\nendmodule\n",
         [f"{w}-bit logic ALU (AND/OR/XOR/NOT)."])
    # arithmetic-only ALU
    emit(f"alu_arithmetic{w}",
         f"module alu_arithmetic{w}(input [{m1}:0] a, input [{m1}:0] b, input [1:0] op, output reg [{m1}:0] y, output reg cout);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define op input {COL['sel']}   // define y output {COL['out']}   // define cout output {COL['flag']}\n"
         f"    // op: 00 add, 01 sub, 10 inc a, 11 dec a\n"
         f"    reg [{w}:0] t;\n"
         f"    always @(*) begin case(op)\n"
         f"        2'b00: t = {{1'b0,a}} + {{1'b0,b}};\n"
         f"        2'b01: t = {{1'b0,a}} - {{1'b0,b}};\n"
         f"        2'b10: t = {{1'b0,a}} + 1'b1;\n"
         f"        2'b11: t = {{1'b0,a}} - 1'b1;\n"
         f"    endcase y=t[{m1}:0]; cout=t[{w}]; end\nendmodule\n",
         [f"{w}-bit arithmetic ALU (add/sub/inc/dec)."])
    # basic ALU (logic+arith, 3-bit op)
    emit(f"alu_basic{w}",
         f"module alu_basic{w}(input [{m1}:0] a, input [{m1}:0] b, input [2:0] op, output reg [{m1}:0] y);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define op input {COL['sel']}   // define y output {COL['out']}\n"
         f"    // op: 000 add 001 sub 010 and 011 or 100 xor 101 not 110 shl 111 shr\n"
         f"    always @(*) case(op)\n"
         f"        3'b000:y=a+b; 3'b001:y=a-b; 3'b010:y=a&b; 3'b011:y=a|b;\n"
         f"        3'b100:y=a^b; 3'b101:y=~a;  3'b110:y=a<<1; 3'b111:y=a>>1;\n"
         f"    endcase\nendmodule\n",
         [f"{w}-bit basic ALU (8 ops)."])
    # ALU with flags
    emit(f"alu_flags{w}",
         f"module alu_flags{w}(input [{m1}:0] a, input [{m1}:0] b, input [2:0] op, output reg [{m1}:0] y, output zero, output negative, output carry, output overflow);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define op input {COL['sel']}\n"
         f"    // define y output {COL['out']}   // define zero output {COL['status']}   // define carry output {COL['flag']}\n"
         f"    reg [{w}:0] t;\n"
         f"    always @(*) begin t={w+1}'b0; case(op)\n"
         f"        3'b000: t={{1'b0,a}}+{{1'b0,b}};\n"
         f"        3'b001: t={{1'b0,a}}-{{1'b0,b}};\n"
         f"        3'b010: t={{1'b0,(a&b)}};\n"
         f"        3'b011: t={{1'b0,(a|b)}};\n"
         f"        3'b100: t={{1'b0,(a^b)}};\n"
         f"        3'b101: t={{1'b0,(~a)}};\n"
         f"        3'b110: t={{1'b0,a}}<<1;\n"
         f"        3'b111: t={{1'b0,a}}>>1;\n"
         f"    endcase y=t[{m1}:0]; end\n"
         f"    assign zero = (y=={w}'b0);\n"
         f"    assign negative = y[{m1}];\n"
         f"    assign carry = t[{w}];\n"
         f"    wire is_add = (op==3'b000);\n"
         f"    wire is_sub = (op==3'b001);\n"
         f"    assign overflow = (is_add & (a[{m1}]==b[{m1}]) & (y[{m1}]!=a[{m1}]))\n"
         f"                    | (is_sub & (a[{m1}]!=b[{m1}]) & (y[{m1}]!=a[{m1}]));\nendmodule\n",
         [f"{w}-bit ALU with Z/N/C/V flags."])
    # ALU with shift ops
    emit(f"alu_shift{w}",
         f"module alu_shift{w}(input [{m1}:0] a, input [{sb-1}:0] sh, input [1:0] op, output reg [{m1}:0] y);\n"
         f"    // define a input {COL['a']}   // define sh input {COL['sel']}   // define op input {COL['sel']}   // define y output {COL['out']}\n"
         f"    // op: 00 shl 01 shr 10 sar 11 rotate-left\n"
         f"    always @(*) case(op)\n"
         f"        2'b00: y = a << sh;\n"
         f"        2'b01: y = a >> sh;\n"
         f"        2'b10: y = $signed(a) >>> sh;\n"
         f"        2'b11: y = (a << sh) | (a >> ({w}-sh));\n"
         f"    endcase\nendmodule\n",
         [f"{w}-bit shift ALU (shl/shr/sar/rol)."])
    # full ALU (op4: arithmetic, logic, shift, compare)
    emit(f"alu_full{w}",
         f"module alu_full{w}(input [{m1}:0] a, input [{m1}:0] b, input [3:0] op,\n"
         f"                   output reg [{m1}:0] y, output zero, output negative, output carry, output overflow);\n"
         f"    // define a input {COL['a']}   // define b input {COL['b']}   // define op input {COL['sel']}\n"
         f"    // define y output {COL['out']}   // define zero output {COL['status']}\n"
         f"    reg [{w}:0] t;\n"
         f"    always @(*) begin t={w+1}'b0; case(op)\n"
         f"        4'h0: t={{1'b0,a}}+{{1'b0,b}};        // ADD\n"
         f"        4'h1: t={{1'b0,a}}-{{1'b0,b}};        // SUB\n"
         f"        4'h2: t={{1'b0,a}}+1'b1;            // INC\n"
         f"        4'h3: t={{1'b0,a}}-1'b1;            // DEC\n"
         f"        4'h4: t={{1'b0,(a&b)}};             // AND\n"
         f"        4'h5: t={{1'b0,(a|b)}};             // OR\n"
         f"        4'h6: t={{1'b0,(a^b)}};             // XOR\n"
         f"        4'h7: t={{1'b0,(~a)}};              // NOT\n"
         f"        4'h8: t={{1'b0,a}}<<1;              // SHL\n"
         f"        4'h9: t={{1'b0,a}}>>1;              // SHR\n"
         f"        4'ha: t={{1'b0,($signed(a)>>>1)}};  // SAR\n"
         f"        4'hb: t={{1'b0,((a<<1)|(a>>{m1}))}};// ROL\n"
         f"        4'hc: t={{{w+1}{{1'b0}}}} | (a<b);    // SLT (unsigned)\n"
         f"        4'hd: t={{{w+1}{{1'b0}}}} | (a==b);   // SEQ\n"
         f"        4'he: t={{1'b0,a}};                 // PASS A\n"
         f"        4'hf: t={{1'b0,b}};                 // PASS B\n"
         f"    endcase y=t[{m1}:0]; end\n"
         f"    assign zero=(y=={w}'b0); assign negative=y[{m1}]; assign carry=t[{w}];\n"
         f"    assign overflow=(op==4'h0)&(a[{m1}]==b[{m1}])&(y[{m1}]!=a[{m1}]);\nendmodule\n",
         [f"{w}-bit full ALU (16 ops + flags)."])
    # datapath pieces
    emit(f"program_counter{w}",
         f"module program_counter{w}(input clk, input rst, input en, input load, input [{m1}:0] addr, output reg [{m1}:0] pc);\n"
         f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define en input {COL['en']}\n"
         f"    // define addr input {COL['a']}   // define pc output {COL['out']}\n"
         f"    always @(posedge clk) if (rst) pc<={w}'b0; else if (load) pc<=addr; else if (en) pc<=pc+1'b1;\nendmodule\n",
         [f"{w}-bit program counter (inc/load/reset)."])
    emit(f"branch_target_adder{w}",
         f"module branch_target_adder{w}(input [{m1}:0] pc, input signed [{m1}:0] offset, output [{m1}:0] target);\n"
         f"    // define pc input {COL['a']}   // define offset input {COL['b']}   // define target output {COL['out']}\n"
         f"    assign target = pc + offset;\nendmodule\n",
         [f"{w}-bit branch-target adder (pc+offset)."])
    emit(f"instruction_register{w}",
         f"module instruction_register{w}(input clk, input rst, input load, input [{m1}:0] din, output reg [{m1}:0] ir);\n"
         f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define load input {COL['en']}\n"
         f"    // define din input {COL['a']}   // define ir output {COL['out']}\n"
         f"    always @(posedge clk) if (rst) ir<={w}'b0; else if (load) ir<=din;\nendmodule\n",
         [f"{w}-bit instruction register."])
    emit(f"stack_pointer{w}",
         f"module stack_pointer{w}(input clk, input rst, input push, input pop, output reg [{m1}:0] sp);\n"
         f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define push input {COL['en']}\n"
         f"    // define sp output {COL['out']}\n"
         f"    always @(posedge clk) if (rst) sp<={{{w}{{1'b1}}}}; else if (push) sp<=sp-1'b1; else if (pop) sp<=sp+1'b1;\nendmodule\n",
         [f"{w}-bit stack pointer (push dec / pop inc)."])
    emit(f"accumulator{w}",
         f"module accumulator{w}(input clk, input rst, input en, input [{m1}:0] din, output reg [{m1}:0] acc);\n"
         f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define en input {COL['en']}\n"
         f"    // define din input {COL['a']}   // define acc output {COL['out']}\n"
         f"    always @(posedge clk) if (rst) acc<={w}'b0; else if (en) acc<=din;\nendmodule\n",
         [f"{w}-bit accumulator register."])
    emit(f"status_register{w}",
         f"module status_register{w}(input clk, input rst, input load, input [{m1}:0] flags_in, output reg [{m1}:0] flags);\n"
         f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define load input {COL['en']}\n"
         f"    // define flags_in input {COL['a']}   // define flags output {COL['out']}\n"
         f"    always @(posedge clk) if (rst) flags<={w}'b0; else if (load) flags<=flags_in;\nendmodule\n",
         [f"{w}-bit status/flags register."])
    # simple datapath: PC + IR + ALU + accumulator skeleton
    emit(f"simple_datapath{w}",
         f"module simple_datapath{w}(input clk, input rst, input [{m1}:0] data_in, input [3:0] alu_op, input acc_en, output [{m1}:0] acc_out, output zero);\n"
         f"    // define clk input {COL['clk']}   // define rst input {COL['rst']}   // define data_in input {COL['a']}\n"
         f"    // define alu_op input {COL['sel']}   // define acc_out output {COL['out']}   // define zero output {COL['status']}\n"
         f"    reg [{m1}:0] acc;\n"
         f"    reg [{w}:0] t;\n"
         f"    always @(*) begin case(alu_op)\n"
         f"        4'h0: t={{1'b0,acc}}+{{1'b0,data_in}};\n"
         f"        4'h1: t={{1'b0,acc}}-{{1'b0,data_in}};\n"
         f"        4'h4: t={{1'b0,(acc&data_in)}};\n"
         f"        4'h5: t={{1'b0,(acc|data_in)}};\n"
         f"        4'h6: t={{1'b0,(acc^data_in)}};\n"
         f"        default: t={{1'b0,data_in}};\n"
         f"    endcase end\n"
         f"    always @(posedge clk) if (rst) acc<={w}'b0; else if (acc_en) acc<=t[{m1}:0];\n"
         f"    assign acc_out=acc; assign zero=(acc=={w}'b0);\nendmodule\n",
         [f"{w}-bit simple accumulator datapath (ALU + accumulator)."])

print("alu/datapath generated")
