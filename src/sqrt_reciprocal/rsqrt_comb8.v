// =====================================================================
//  rsqrt_comb8.v
//  8-bit reciprocal square root (structural sqrt + structural reciprocal divide).
//  No *, /, % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rsqrt_comb8(input [7:0] a, output [7:0] result, output valid);
    // define a input 80.160.255
    // define result output 120.255.160
    // define valid output 255.255.255
    // 1/sqrt(a) scaled: (2^8-1) / floor(sqrt(a)), fully structural
    wire [3:0] rt; wire [4:0] rm;
    rsqcore8 sc(.a(a), .root(rt), .rem(rm));
    wire [7:0] rt_ext = {{4{1'b0}}, rt};
    wire azero = ~(|a);
    wire [7:0] num = {8{1'b1}};   // 2^8-1 numerator
    wire [7:0] q, r; wire rd0,rov,rv,rb,rdn;
    rsqdiv8 dv(.a(num), .b(rt_ext), .quotient(q), .remainder(r),
        .divide_by_zero(rd0), .overflow(rov), .valid(rv), .busy(rb), .done(rdn));
    assign result = azero ? {8{1'b1}} : q;
    assign valid = ~azero;
endmodule

module rsqcore8(input [7:0] a, output [3:0] root, output [4:0] rem);
    wire [9:0] rem0 = {10{1'b0}};
    wire [3:0] root0 = {4{1'b0}};
    wire [9:0] sr0 = {rem0[7:0], a[7], a[6]};
    wire [9:0] ts0 = {root0, 2'b01};
    wire [9:0] df0; wire bw0;
    sqsub10_0 ss0(.a(sr0), .b(ts0), .diff(df0), .bout(bw0));
    wire ge0 = ~bw0;
    wire [9:0] rem1 = ge0 ? df0 : sr0;
    wire [3:0] root1 = {root0[2:0], ge0};
    wire [9:0] sr1 = {rem1[7:0], a[5], a[4]};
    wire [9:0] ts1 = {root1, 2'b01};
    wire [9:0] df1; wire bw1;
    sqsub10_1 ss1(.a(sr1), .b(ts1), .diff(df1), .bout(bw1));
    wire ge1 = ~bw1;
    wire [9:0] rem2 = ge1 ? df1 : sr1;
    wire [3:0] root2 = {root1[2:0], ge1};
    wire [9:0] sr2 = {rem2[7:0], a[3], a[2]};
    wire [9:0] ts2 = {root2, 2'b01};
    wire [9:0] df2; wire bw2;
    sqsub10_2 ss2(.a(sr2), .b(ts2), .diff(df2), .bout(bw2));
    wire ge2 = ~bw2;
    wire [9:0] rem3 = ge2 ? df2 : sr2;
    wire [3:0] root3 = {root2[2:0], ge2};
    wire [9:0] sr3 = {rem3[7:0], a[1], a[0]};
    wire [9:0] ts3 = {root3, 2'b01};
    wire [9:0] df3; wire bw3;
    sqsub10_3 ss3(.a(sr3), .b(ts3), .diff(df3), .bout(bw3));
    wire ge3 = ~bw3;
    wire [9:0] rem4 = ge3 ? df3 : sr3;
    wire [3:0] root4 = {root3[2:0], ge3};
    assign root = root4;
    assign rem  = rem4[4:0];
endmodule

module sqsub10_0(input [9:0] a, input [9:0] b, output [9:0] diff, output bout);
    wire [10:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    assign bout = ~c[10];
endmodule

module sqsub10_1(input [9:0] a, input [9:0] b, output [9:0] diff, output bout);
    wire [10:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    assign bout = ~c[10];
endmodule

module sqsub10_2(input [9:0] a, input [9:0] b, output [9:0] diff, output bout);
    wire [10:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    assign bout = ~c[10];
endmodule

module sqsub10_3(input [9:0] a, input [9:0] b, output [9:0] diff, output bout);
    wire [10:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    assign bout = ~c[10];
endmodule


module rsqdiv8(input [7:0] a, input [7:0] b,
    output [7:0] quotient, output [7:0] remainder,
    output divide_by_zero, output overflow, output valid, output busy, output done);
    wire dz = ~(|b);
    wire [8:0] rem0 = {9{1'b0}};
    wire [8:0] sh0 = {rem0[7:0], a[7]};
    wire [8:0] tr0; wire bo0;
    subw9_0 sub0(.a(sh0), .b({1'b0,b}), .diff(tr0), .bout(bo0));
    wire q0 = ~bo0;
    wire [8:0] rem1 = q0 ? tr0 : sh0;
    wire [8:0] sh1 = {rem1[7:0], a[6]};
    wire [8:0] tr1; wire bo1;
    subw9_1 sub1(.a(sh1), .b({1'b0,b}), .diff(tr1), .bout(bo1));
    wire q1 = ~bo1;
    wire [8:0] rem2 = q1 ? tr1 : sh1;
    wire [8:0] sh2 = {rem2[7:0], a[5]};
    wire [8:0] tr2; wire bo2;
    subw9_2 sub2(.a(sh2), .b({1'b0,b}), .diff(tr2), .bout(bo2));
    wire q2 = ~bo2;
    wire [8:0] rem3 = q2 ? tr2 : sh2;
    wire [8:0] sh3 = {rem3[7:0], a[4]};
    wire [8:0] tr3; wire bo3;
    subw9_3 sub3(.a(sh3), .b({1'b0,b}), .diff(tr3), .bout(bo3));
    wire q3 = ~bo3;
    wire [8:0] rem4 = q3 ? tr3 : sh3;
    wire [8:0] sh4 = {rem4[7:0], a[3]};
    wire [8:0] tr4; wire bo4;
    subw9_4 sub4(.a(sh4), .b({1'b0,b}), .diff(tr4), .bout(bo4));
    wire q4 = ~bo4;
    wire [8:0] rem5 = q4 ? tr4 : sh4;
    wire [8:0] sh5 = {rem5[7:0], a[2]};
    wire [8:0] tr5; wire bo5;
    subw9_5 sub5(.a(sh5), .b({1'b0,b}), .diff(tr5), .bout(bo5));
    wire q5 = ~bo5;
    wire [8:0] rem6 = q5 ? tr5 : sh5;
    wire [8:0] sh6 = {rem6[7:0], a[1]};
    wire [8:0] tr6; wire bo6;
    subw9_6 sub6(.a(sh6), .b({1'b0,b}), .diff(tr6), .bout(bo6));
    wire q6 = ~bo6;
    wire [8:0] rem7 = q6 ? tr6 : sh6;
    wire [8:0] sh7 = {rem7[7:0], a[0]};
    wire [8:0] tr7; wire bo7;
    subw9_7 sub7(.a(sh7), .b({1'b0,b}), .diff(tr7), .bout(bo7));
    wire q7 = ~bo7;
    wire [8:0] rem8 = q7 ? tr7 : sh7;
    assign quotient  = dz ? {8{1'b1}} : {q0, q1, q2, q3, q4, q5, q6, q7};
    assign remainder = dz ? a : rem8[7:0];
    assign overflow = 1'b0;
    assign valid = ~dz;
    assign busy  = 1'b0;
    assign done  = 1'b1;
endmodule

module subw9_0(input [8:0] a, input [8:0] b, output [8:0] diff, output bout);
    wire [9:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    assign bout = ~c[9];
endmodule

module subw9_1(input [8:0] a, input [8:0] b, output [8:0] diff, output bout);
    wire [9:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    assign bout = ~c[9];
endmodule

module subw9_2(input [8:0] a, input [8:0] b, output [8:0] diff, output bout);
    wire [9:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    assign bout = ~c[9];
endmodule

module subw9_3(input [8:0] a, input [8:0] b, output [8:0] diff, output bout);
    wire [9:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    assign bout = ~c[9];
endmodule

module subw9_4(input [8:0] a, input [8:0] b, output [8:0] diff, output bout);
    wire [9:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    assign bout = ~c[9];
endmodule

module subw9_5(input [8:0] a, input [8:0] b, output [8:0] diff, output bout);
    wire [9:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    assign bout = ~c[9];
endmodule

module subw9_6(input [8:0] a, input [8:0] b, output [8:0] diff, output bout);
    wire [9:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    assign bout = ~c[9];
endmodule

module subw9_7(input [8:0] a, input [8:0] b, output [8:0] diff, output bout);
    wire [9:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    assign bout = ~c[9];
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


