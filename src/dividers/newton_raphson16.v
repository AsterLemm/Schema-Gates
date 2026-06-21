// =====================================================================
//  newton_raphson16.v
//  16-bit Newton-Raphson divider (result via structural restoring array); no / or % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module newton_raphson16(input [15:0] a, input [15:0] b, output [15:0] quotient, output valid);
    // define a input 80.160.255
    // define b input 80.200.255
    // define quotient output 120.255.160
    wire dz=~(|b); assign valid=~dz;
    wire [15:0] q, r; wire d2,o2,v2,b2,dn2;
    newton_raphsoncore16 dv(.a(a),.b(b),.quotient(q),.remainder(r),.divide_by_zero(d2),.overflow(o2),.valid(v2),.busy(b2),.done(dn2));
    assign quotient = dz ? {16{1'b1}} : q;
endmodule

module newton_raphsoncore16(input [15:0] a, input [15:0] b,
    output [15:0] quotient, output [15:0] remainder,
    output divide_by_zero, output overflow, output valid, output busy, output done);
    wire dz = ~(|b);
    wire [16:0] rem0 = {17{1'b0}};
    wire [16:0] sh0 = {rem0[15:0], a[15]};
    wire [16:0] tr0; wire bo0;
    subw17_0 sub0(.a(sh0), .b({1'b0,b}), .diff(tr0), .bout(bo0));
    wire q0 = ~bo0;
    wire [16:0] rem1 = q0 ? tr0 : sh0;
    wire [16:0] sh1 = {rem1[15:0], a[14]};
    wire [16:0] tr1; wire bo1;
    subw17_1 sub1(.a(sh1), .b({1'b0,b}), .diff(tr1), .bout(bo1));
    wire q1 = ~bo1;
    wire [16:0] rem2 = q1 ? tr1 : sh1;
    wire [16:0] sh2 = {rem2[15:0], a[13]};
    wire [16:0] tr2; wire bo2;
    subw17_2 sub2(.a(sh2), .b({1'b0,b}), .diff(tr2), .bout(bo2));
    wire q2 = ~bo2;
    wire [16:0] rem3 = q2 ? tr2 : sh2;
    wire [16:0] sh3 = {rem3[15:0], a[12]};
    wire [16:0] tr3; wire bo3;
    subw17_3 sub3(.a(sh3), .b({1'b0,b}), .diff(tr3), .bout(bo3));
    wire q3 = ~bo3;
    wire [16:0] rem4 = q3 ? tr3 : sh3;
    wire [16:0] sh4 = {rem4[15:0], a[11]};
    wire [16:0] tr4; wire bo4;
    subw17_4 sub4(.a(sh4), .b({1'b0,b}), .diff(tr4), .bout(bo4));
    wire q4 = ~bo4;
    wire [16:0] rem5 = q4 ? tr4 : sh4;
    wire [16:0] sh5 = {rem5[15:0], a[10]};
    wire [16:0] tr5; wire bo5;
    subw17_5 sub5(.a(sh5), .b({1'b0,b}), .diff(tr5), .bout(bo5));
    wire q5 = ~bo5;
    wire [16:0] rem6 = q5 ? tr5 : sh5;
    wire [16:0] sh6 = {rem6[15:0], a[9]};
    wire [16:0] tr6; wire bo6;
    subw17_6 sub6(.a(sh6), .b({1'b0,b}), .diff(tr6), .bout(bo6));
    wire q6 = ~bo6;
    wire [16:0] rem7 = q6 ? tr6 : sh6;
    wire [16:0] sh7 = {rem7[15:0], a[8]};
    wire [16:0] tr7; wire bo7;
    subw17_7 sub7(.a(sh7), .b({1'b0,b}), .diff(tr7), .bout(bo7));
    wire q7 = ~bo7;
    wire [16:0] rem8 = q7 ? tr7 : sh7;
    wire [16:0] sh8 = {rem8[15:0], a[7]};
    wire [16:0] tr8; wire bo8;
    subw17_8 sub8(.a(sh8), .b({1'b0,b}), .diff(tr8), .bout(bo8));
    wire q8 = ~bo8;
    wire [16:0] rem9 = q8 ? tr8 : sh8;
    wire [16:0] sh9 = {rem9[15:0], a[6]};
    wire [16:0] tr9; wire bo9;
    subw17_9 sub9(.a(sh9), .b({1'b0,b}), .diff(tr9), .bout(bo9));
    wire q9 = ~bo9;
    wire [16:0] rem10 = q9 ? tr9 : sh9;
    wire [16:0] sh10 = {rem10[15:0], a[5]};
    wire [16:0] tr10; wire bo10;
    subw17_10 sub10(.a(sh10), .b({1'b0,b}), .diff(tr10), .bout(bo10));
    wire q10 = ~bo10;
    wire [16:0] rem11 = q10 ? tr10 : sh10;
    wire [16:0] sh11 = {rem11[15:0], a[4]};
    wire [16:0] tr11; wire bo11;
    subw17_11 sub11(.a(sh11), .b({1'b0,b}), .diff(tr11), .bout(bo11));
    wire q11 = ~bo11;
    wire [16:0] rem12 = q11 ? tr11 : sh11;
    wire [16:0] sh12 = {rem12[15:0], a[3]};
    wire [16:0] tr12; wire bo12;
    subw17_12 sub12(.a(sh12), .b({1'b0,b}), .diff(tr12), .bout(bo12));
    wire q12 = ~bo12;
    wire [16:0] rem13 = q12 ? tr12 : sh12;
    wire [16:0] sh13 = {rem13[15:0], a[2]};
    wire [16:0] tr13; wire bo13;
    subw17_13 sub13(.a(sh13), .b({1'b0,b}), .diff(tr13), .bout(bo13));
    wire q13 = ~bo13;
    wire [16:0] rem14 = q13 ? tr13 : sh13;
    wire [16:0] sh14 = {rem14[15:0], a[1]};
    wire [16:0] tr14; wire bo14;
    subw17_14 sub14(.a(sh14), .b({1'b0,b}), .diff(tr14), .bout(bo14));
    wire q14 = ~bo14;
    wire [16:0] rem15 = q14 ? tr14 : sh14;
    wire [16:0] sh15 = {rem15[15:0], a[0]};
    wire [16:0] tr15; wire bo15;
    subw17_15 sub15(.a(sh15), .b({1'b0,b}), .diff(tr15), .bout(bo15));
    wire q15 = ~bo15;
    wire [16:0] rem16 = q15 ? tr15 : sh15;
    assign quotient  = dz ? {16{1'b1}} : {q0, q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15};
    assign remainder = dz ? a : rem16[15:0];
    assign overflow = 1'b0;
    assign valid = ~dz;
    assign busy  = 1'b0;
    assign done  = 1'b1;
endmodule

module subw17_0(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_1(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_2(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_3(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_4(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_5(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_6(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_7(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_8(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_9(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_10(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_11(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_12(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_13(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_14(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_15(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
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
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
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


