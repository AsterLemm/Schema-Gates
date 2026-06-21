// =====================================================================
//  mul_sign_magnitude8.v
//  8x8 sign-magnitude multiplier.
//  Structural magnitude array multiply; no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mul_sign_magnitude8(input [7:0] a, input [7:0] b, output [15:0] product);
    // define a input 80.160.255
    // define b input 80.200.255
    // define product output 120.255.160
    wire sgn = a[7] ^ b[7];
    wire [7:0] ma = {1'b0, a[6:0]};
    wire [7:0] mb = {1'b0, b[6:0]};
    wire [15:0] mag;
    smcore8 mm(.a(ma),.b(mb),.product(mag));
    assign product = {sgn, mag[14:0]};
endmodule

module smcore8(input [7:0] a, input [7:0] b, output [15:0] product);
    wire pp0_0 = a[0] & b[0];
    wire pp0_1 = a[1] & b[0];
    wire pp0_2 = a[2] & b[0];
    wire pp0_3 = a[3] & b[0];
    wire pp0_4 = a[4] & b[0];
    wire pp0_5 = a[5] & b[0];
    wire pp0_6 = a[6] & b[0];
    wire pp0_7 = a[7] & b[0];
    wire pp1_0 = a[0] & b[1];
    wire pp1_1 = a[1] & b[1];
    wire pp1_2 = a[2] & b[1];
    wire pp1_3 = a[3] & b[1];
    wire pp1_4 = a[4] & b[1];
    wire pp1_5 = a[5] & b[1];
    wire pp1_6 = a[6] & b[1];
    wire pp1_7 = a[7] & b[1];
    wire pp2_0 = a[0] & b[2];
    wire pp2_1 = a[1] & b[2];
    wire pp2_2 = a[2] & b[2];
    wire pp2_3 = a[3] & b[2];
    wire pp2_4 = a[4] & b[2];
    wire pp2_5 = a[5] & b[2];
    wire pp2_6 = a[6] & b[2];
    wire pp2_7 = a[7] & b[2];
    wire pp3_0 = a[0] & b[3];
    wire pp3_1 = a[1] & b[3];
    wire pp3_2 = a[2] & b[3];
    wire pp3_3 = a[3] & b[3];
    wire pp3_4 = a[4] & b[3];
    wire pp3_5 = a[5] & b[3];
    wire pp3_6 = a[6] & b[3];
    wire pp3_7 = a[7] & b[3];
    wire pp4_0 = a[0] & b[4];
    wire pp4_1 = a[1] & b[4];
    wire pp4_2 = a[2] & b[4];
    wire pp4_3 = a[3] & b[4];
    wire pp4_4 = a[4] & b[4];
    wire pp4_5 = a[5] & b[4];
    wire pp4_6 = a[6] & b[4];
    wire pp4_7 = a[7] & b[4];
    wire pp5_0 = a[0] & b[5];
    wire pp5_1 = a[1] & b[5];
    wire pp5_2 = a[2] & b[5];
    wire pp5_3 = a[3] & b[5];
    wire pp5_4 = a[4] & b[5];
    wire pp5_5 = a[5] & b[5];
    wire pp5_6 = a[6] & b[5];
    wire pp5_7 = a[7] & b[5];
    wire pp6_0 = a[0] & b[6];
    wire pp6_1 = a[1] & b[6];
    wire pp6_2 = a[2] & b[6];
    wire pp6_3 = a[3] & b[6];
    wire pp6_4 = a[4] & b[6];
    wire pp6_5 = a[5] & b[6];
    wire pp6_6 = a[6] & b[6];
    wire pp6_7 = a[7] & b[6];
    wire pp7_0 = a[0] & b[7];
    wire pp7_1 = a[1] & b[7];
    wire pp7_2 = a[2] & b[7];
    wire pp7_3 = a[3] & b[7];
    wire pp7_4 = a[4] & b[7];
    wire pp7_5 = a[5] & b[7];
    wire pp7_6 = a[6] & b[7];
    wire pp7_7 = a[7] & b[7];
    wire [15:0] row0 = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, pp0_7, pp0_6, pp0_5, pp0_4, pp0_3, pp0_2, pp0_1, pp0_0};
    wire [15:0] row1 = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, pp1_7, pp1_6, pp1_5, pp1_4, pp1_3, pp1_2, pp1_1, pp1_0, 1'b0};
    wire [15:0] row2 = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, pp2_7, pp2_6, pp2_5, pp2_4, pp2_3, pp2_2, pp2_1, pp2_0, 1'b0, 1'b0};
    wire [15:0] row3 = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, pp3_7, pp3_6, pp3_5, pp3_4, pp3_3, pp3_2, pp3_1, pp3_0, 1'b0, 1'b0, 1'b0};
    wire [15:0] row4 = {1'b0, 1'b0, 1'b0, 1'b0, pp4_7, pp4_6, pp4_5, pp4_4, pp4_3, pp4_2, pp4_1, pp4_0, 1'b0, 1'b0, 1'b0, 1'b0};
    wire [15:0] row5 = {1'b0, 1'b0, 1'b0, pp5_7, pp5_6, pp5_5, pp5_4, pp5_3, pp5_2, pp5_1, pp5_0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
    wire [15:0] row6 = {1'b0, 1'b0, pp6_7, pp6_6, pp6_5, pp6_4, pp6_3, pp6_2, pp6_1, pp6_0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
    wire [15:0] row7 = {1'b0, pp7_7, pp7_6, pp7_5, pp7_4, pp7_3, pp7_2, pp7_1, pp7_0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0};
    wire [15:0] acc1; wire co1;
    rca16 add1(.a(row0),.b(row1),.cin(1'b0),.sum(acc1),.cout(co1));
    wire [15:0] acc2; wire co2;
    rca16 add2(.a(acc1),.b(row2),.cin(1'b0),.sum(acc2),.cout(co2));
    wire [15:0] acc3; wire co3;
    rca16 add3(.a(acc2),.b(row3),.cin(1'b0),.sum(acc3),.cout(co3));
    wire [15:0] acc4; wire co4;
    rca16 add4(.a(acc3),.b(row4),.cin(1'b0),.sum(acc4),.cout(co4));
    wire [15:0] acc5; wire co5;
    rca16 add5(.a(acc4),.b(row5),.cin(1'b0),.sum(acc5),.cout(co5));
    wire [15:0] acc6; wire co6;
    rca16 add6(.a(acc5),.b(row6),.cin(1'b0),.sum(acc6),.cout(co6));
    wire [15:0] acc7; wire co7;
    rca16 add7(.a(acc6),.b(row7),.cin(1'b0),.sum(acc7),.cout(co7));
    assign product = acc7;
endmodule

module rca16(input [15:0] a, input [15:0] b, input cin, output [15:0] sum, output cout);
    wire [16:0] c; assign c[0]=cin;
    full_adder fa0(.a(a[0]),.b(b[0]),.cin(c[0]),.sum(sum[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(b[1]),.cin(c[1]),.sum(sum[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(b[2]),.cin(c[2]),.sum(sum[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(b[3]),.cin(c[3]),.sum(sum[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(b[4]),.cin(c[4]),.sum(sum[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(b[5]),.cin(c[5]),.sum(sum[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(b[6]),.cin(c[6]),.sum(sum[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(b[7]),.cin(c[7]),.sum(sum[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(b[8]),.cin(c[8]),.sum(sum[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(b[9]),.cin(c[9]),.sum(sum[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(b[10]),.cin(c[10]),.sum(sum[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(b[11]),.cin(c[11]),.sum(sum[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(b[12]),.cin(c[12]),.sum(sum[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(b[13]),.cin(c[13]),.sum(sum[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(b[14]),.cin(c[14]),.sum(sum[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(b[15]),.cin(c[15]),.sum(sum[15]),.cout(c[16]));
    assign cout=c[16];
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


