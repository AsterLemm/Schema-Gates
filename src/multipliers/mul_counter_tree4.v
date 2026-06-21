// =====================================================================
//  mul_counter_tree4.v
//  4x4 counter-based reduction-tree multiplier.
//  Structural compressor tree of full adders; no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mul_counter_tree4(input [3:0] a, input [3:0] b, output [7:0] product);
    // define a input 80.160.255
    // define b input 80.200.255
    // define product output 120.255.160
    wire pp0_0 = a[0] & b[0];
    wire pp0_1 = a[1] & b[0];
    wire pp0_2 = a[2] & b[0];
    wire pp0_3 = a[3] & b[0];
    wire pp1_0 = a[0] & b[1];
    wire pp1_1 = a[1] & b[1];
    wire pp1_2 = a[2] & b[1];
    wire pp1_3 = a[3] & b[1];
    wire pp2_0 = a[0] & b[2];
    wire pp2_1 = a[1] & b[2];
    wire pp2_2 = a[2] & b[2];
    wire pp2_3 = a[3] & b[2];
    wire pp3_0 = a[0] & b[3];
    wire pp3_1 = a[1] & b[3];
    wire pp3_2 = a[2] & b[3];
    wire pp3_3 = a[3] & b[3];
    wire w1, w2;
    full_adder fc2(.a(pp0_2),.b(pp1_1),.cin(pp2_0),.sum(w1),.cout(w2));
    wire w3, w4;
    full_adder fc4(.a(pp0_3),.b(pp1_2),.cin(pp2_1),.sum(w3),.cout(w4));
    wire w5, w6;
    full_adder fc6(.a(pp3_0),.b(w2),.cin(w3),.sum(w5),.cout(w6));
    wire w7, w8;
    full_adder fc8(.a(pp1_3),.b(pp2_2),.cin(pp3_1),.sum(w7),.cout(w8));
    wire w9, w10;
    full_adder fc10(.a(w4),.b(w6),.cin(w7),.sum(w9),.cout(w10));
    wire w11, w12;
    full_adder fc12(.a(pp2_3),.b(pp3_2),.cin(w8),.sum(w11),.cout(w12));
    wire [7:0] opA = {1'b0, pp3_3, w10, w9, w5, w1, pp0_1, pp0_0};
    wire [7:0] opB = {1'b0, w12, w11, 1'b0, 1'b0, 1'b0, pp1_0, 1'b0};
    wire co_f;
    rca8 final_add(.a(opA),.b(opB),.cin(1'b0),.sum(product),.cout(co_f));
endmodule

module rca8(input [7:0] a, input [7:0] b, input cin, output [7:0] sum, output cout);
    wire [8:0] c; assign c[0]=cin;
    full_adder fa0(.a(a[0]),.b(b[0]),.cin(c[0]),.sum(sum[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(b[1]),.cin(c[1]),.sum(sum[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(b[2]),.cin(c[2]),.sum(sum[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(b[3]),.cin(c[3]),.sum(sum[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(b[4]),.cin(c[4]),.sum(sum[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(b[5]),.cin(c[5]),.sum(sum[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(b[6]),.cin(c[6]),.sum(sum[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(b[7]),.cin(c[7]),.sum(sum[7]),.cout(c[8]));
    assign cout=c[8];
endmodule

module half_adder(input a, input b, output sum, output carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule

module full_adder(input a, input b, input cin, output sum, output cout);
    wire s0, c0, c1;
    half_adder ha0(.a(a),  .b(b),   .sum(s0),  .carry(c0));
    half_adder ha1(.a(s0), .b(cin), .sum(sum), .carry(c1));
    assign cout = c0 | c1;
endmodule


