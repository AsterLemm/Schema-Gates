// =====================================================================
//  rsqrt_comb4.v
//  4-bit reciprocal square root (structural sqrt + structural reciprocal divide).
//  No *, /, % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rsqrt_comb4(input [3:0] a, output [3:0] result, output valid);
    // define a input 80.160.255
    // define result output 120.255.160
    // define valid output 255.255.255
    // 1/sqrt(a) scaled: (2^4-1) / floor(sqrt(a)), fully structural
    wire [1:0] rt; wire [2:0] rm;
    rsqcore4 sc(.a(a), .root(rt), .rem(rm));
    wire [3:0] rt_ext = {{2{1'b0}}, rt};
    wire azero = ~(|a);
    wire [3:0] num = {4{1'b1}};   // 2^4-1 numerator
    wire [3:0] q, r; wire rd0,rov,rv,rb,rdn;
    rsqdiv4 dv(.a(num), .b(rt_ext), .quotient(q), .remainder(r),
        .divide_by_zero(rd0), .overflow(rov), .valid(rv), .busy(rb), .done(rdn));
    assign result = azero ? {4{1'b1}} : q;
    assign valid = ~azero;
endmodule

module rsqcore4(input [3:0] a, output [1:0] root, output [2:0] rem);
    wire [5:0] rem0 = {6{1'b0}};
    wire [1:0] root0 = {2{1'b0}};
    wire [5:0] sr0 = {rem0[3:0], a[3], a[2]};
    wire [5:0] ts0 = {root0, 2'b01};
    wire [5:0] df0; wire bw0;
    sqsub6_0 ss0(.a(sr0), .b(ts0), .diff(df0), .bout(bw0));
    wire ge0 = ~bw0;
    wire [5:0] rem1 = ge0 ? df0 : sr0;
    wire [1:0] root1 = {root0[0:0], ge0};
    wire [5:0] sr1 = {rem1[3:0], a[1], a[0]};
    wire [5:0] ts1 = {root1, 2'b01};
    wire [5:0] df1; wire bw1;
    sqsub6_1 ss1(.a(sr1), .b(ts1), .diff(df1), .bout(bw1));
    wire ge1 = ~bw1;
    wire [5:0] rem2 = ge1 ? df1 : sr1;
    wire [1:0] root2 = {root1[0:0], ge1};
    assign root = root2;
    assign rem  = rem2[2:0];
endmodule

module sqsub6_0(input [5:0] a, input [5:0] b, output [5:0] diff, output bout);
    wire [6:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    assign bout = ~c[6];
endmodule

module sqsub6_1(input [5:0] a, input [5:0] b, output [5:0] diff, output bout);
    wire [6:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    assign bout = ~c[6];
endmodule


module rsqdiv4(input [3:0] a, input [3:0] b,
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


