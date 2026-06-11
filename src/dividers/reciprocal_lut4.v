// =====================================================================
//  reciprocal_lut4.v
//  4-bit reciprocal (structural division of (2^4-1) by a); no / or % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module reciprocal_lut4(input [3:0] a, output [3:0] recip, output valid);
    // define a input 80.160.255   // define recip output 120.255.160   // define valid output 255.255.255
    wire dz=~(|a); assign valid=~dz;
    wire [3:0] num = {4{1'b1}};   // (2^4-1) numerator
    wire [3:0] q, r; wire d2,o2,v2,b2,dn2;
    recipcore4 dv(.a(num),.b(a),.quotient(q),.remainder(r),.divide_by_zero(d2),.overflow(o2),.valid(v2),.busy(b2),.done(dn2));
    assign recip = dz ? {4{1'b1}} : q;
endmodule

module recipcore4(input [3:0] a, input [3:0] b,
    output [3:0] quotient, output [3:0] remainder,
    output divide_by_zero, output overflow, output valid, output busy, output done);
    wire dz = ~(|b);
    wire [4:0] rem0 = {5{1'b0}};
    wire [4:0] sh0 = {rem0[3:0], a[3]};
    wire [4:0] tr0; wire bo0;
    subw5_0 sub0(.a(sh0), .b({1'b0,b}), .diff(tr0), .bout(bo0));
    wire q0 = ~bo0;
    wire [4:0] rem1 = q0 ? tr0 : sh0;
    wire [4:0] sh1 = {rem1[3:0], a[2]};
    wire [4:0] tr1; wire bo1;
    subw5_1 sub1(.a(sh1), .b({1'b0,b}), .diff(tr1), .bout(bo1));
    wire q1 = ~bo1;
    wire [4:0] rem2 = q1 ? tr1 : sh1;
    wire [4:0] sh2 = {rem2[3:0], a[1]};
    wire [4:0] tr2; wire bo2;
    subw5_2 sub2(.a(sh2), .b({1'b0,b}), .diff(tr2), .bout(bo2));
    wire q2 = ~bo2;
    wire [4:0] rem3 = q2 ? tr2 : sh2;
    wire [4:0] sh3 = {rem3[3:0], a[0]};
    wire [4:0] tr3; wire bo3;
    subw5_3 sub3(.a(sh3), .b({1'b0,b}), .diff(tr3), .bout(bo3));
    wire q3 = ~bo3;
    wire [4:0] rem4 = q3 ? tr3 : sh3;
    assign quotient  = dz ? {4{1'b1}} : {q0, q1, q2, q3};
    assign remainder = dz ? a : rem4[3:0];
    assign overflow = 1'b0;
    assign valid = ~dz;
    assign busy  = 1'b0;
    assign done  = 1'b1;
endmodule

module subw5_0(input [4:0] a, input [4:0] b, output [4:0] diff, output bout);
    wire [5:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    assign bout = ~c[5];
endmodule

module subw5_1(input [4:0] a, input [4:0] b, output [4:0] diff, output bout);
    wire [5:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    assign bout = ~c[5];
endmodule

module subw5_2(input [4:0] a, input [4:0] b, output [4:0] diff, output bout);
    wire [5:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    assign bout = ~c[5];
endmodule

module subw5_3(input [4:0] a, input [4:0] b, output [4:0] diff, output bout);
    wire [5:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    assign bout = ~c[5];
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


