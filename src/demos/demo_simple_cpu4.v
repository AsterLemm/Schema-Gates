// =====================================================================
//  demo_simple_cpu4.v
//  Demo: tiny 4-bit accumulator CPU (8 ops).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module demo_simple_cpu4(input clk, input rst, input [7:0] instr, output [3:0] acc_out, output zero);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define instr input 80.160.255
    // define acc_out output 120.255.160
    // define zero output 255.255.255
    // instr = {opcode[3:0], operand[3:0]}
    // opcodes: 0 LOAD, 1 ADD, 2 SUB, 3 AND, 4 OR, 5 XOR, 6 SHL, 7 SHR
    reg [3:0] acc;
    wire [3:0] opcode = instr[7:4];
    wire [3:0] operand = instr[3:0];
    reg [3:0] next;
    always @(*) begin case(opcode)
        4'd0: next=operand;
        4'd1: next=acc+operand;
        4'd2: next=acc-operand;
        4'd3: next=acc&operand;
        4'd4: next=acc|operand;
        4'd5: next=acc^operand;
        4'd6: next=acc<<1;
        4'd7: next=acc>>1;
        default: next=acc;
    endcase end
    always @(posedge clk) if (rst) acc<=4'b0; else acc<=next;
    assign acc_out=acc; assign zero=(acc==4'b0);
endmodule


