// =====================================================================
//  mul_const3_4.v
//  4-bit multiply-by-3 (a<<1 + a).
//  Structural shift-add; no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mul_const3_4(input [3:0] a, output [5:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    wire [5:0] t_1 = {{2{1'b0}}, a} << 1;
    wire [5:0] t_0 = {{2{1'b0}}, a} << 0;
    wire [5:0] s0; wire c0;
    rca6 ad0(.a(t_1),.b(t_0),.cin(1'b0),.sum(s0),.cout(c0));
    assign y = s0;
endmodule

module rca6(input [5:0] a, input [5:0] b, input cin, output [5:0] sum, output cout);
    wire [6:0] c; assign c[0]=cin;
    full_adder fa0(.a(a[0]),.b(b[0]),.cin(c[0]),.sum(sum[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(b[1]),.cin(c[1]),.sum(sum[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(b[2]),.cin(c[2]),.sum(sum[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(b[3]),.cin(c[3]),.sum(sum[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(b[4]),.cin(c[4]),.sum(sum[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(b[5]),.cin(c[5]),.sum(sum[5]),.cout(c[6]));
    assign cout=c[6];
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


