// =====================================================================
//  mod_signed8.v
//  8-bit signed modulo.
//  Structural signed restoring array; no / or % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mod_signed8(input signed [7:0] a, input signed [7:0] b, output signed [7:0] remainder, output divide_by_zero, output valid, output busy, output done);
    // define a input 80.160.255
    // define b input 80.200.255
    // define remainder output 120.255.160
    wire dz=~(|b);
    wire [7:0] q_unused, r;
    wire d2,o2,v2,b2,dn2;
    div_sgncore8 dv(.a(a),.b(b),.quotient(q_unused),.remainder(r),.divide_by_zero(d2),.overflow(o2),.valid(v2),.busy(b2),.done(dn2));
    assign remainder = dz ? a : r;
    assign divide_by_zero=dz; assign valid=~dz; assign busy=1'b0; assign done=1'b1;
endmodule

module div_sgncore8(input signed [7:0] a, input signed [7:0] b,
    output signed [7:0] quotient, output signed [7:0] remainder,
    output divide_by_zero, output overflow, output valid, output busy, output done);
    wire dz = ~(|b);
    wire sa=a[7], sb=b[7];
    wire [7:0] mag_a, mag_b; wire ca,cb;
    wire [7:0] ai = a ^ {8{sa}}, bi = b ^ {8{sb}};
    cincd8 na(.a(ai),.add(sa),.y(mag_a),.cout(ca));
    cincd8 nb(.a(bi),.add(sb),.y(mag_b),.cout(cb));
    wire [7:0] uq, ur; wire udz,uov,uv,ub,ud;
    udivcore8 dv(.a(mag_a),.b(mag_b),.quotient(uq),.remainder(ur),
        .divide_by_zero(udz),.overflow(uov),.valid(uv),.busy(ub),.done(ud));
    wire qs = sa ^ sb;
    wire [7:0] uq_i = uq ^ {8{qs}}; wire [7:0] q_fixed; wire qc;
    cincd8 fq(.a(uq_i),.add(qs),.y(q_fixed),.cout(qc));
    wire [7:0] ur_i = ur ^ {8{sa}}; wire [7:0] r_fixed; wire rc;
    cincd8 fr(.a(ur_i),.add(sa),.y(r_fixed),.cout(rc));
    assign quotient  = dz ? {8{1'b1}} : q_fixed;
    assign remainder = dz ? a : r_fixed;
    assign overflow = 1'b0; assign valid=~dz; assign busy=1'b0; assign done=1'b1;
endmodule

module udivcore8(input [7:0] a, input [7:0] b,
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

module cincd8(input [7:0] a, input add, output [7:0] y, output cout);
    wire [8:0] c; assign c[0]=add;
    half_adder h0(.a(a[0]),.b(c[0]),.sum(y[0]),.carry(c[1]));
    half_adder h1(.a(a[1]),.b(c[1]),.sum(y[1]),.carry(c[2]));
    half_adder h2(.a(a[2]),.b(c[2]),.sum(y[2]),.carry(c[3]));
    half_adder h3(.a(a[3]),.b(c[3]),.sum(y[3]),.carry(c[4]));
    half_adder h4(.a(a[4]),.b(c[4]),.sum(y[4]),.carry(c[5]));
    half_adder h5(.a(a[5]),.b(c[5]),.sum(y[5]),.carry(c[6]));
    half_adder h6(.a(a[6]),.b(c[6]),.sum(y[6]),.carry(c[7]));
    half_adder h7(.a(a[7]),.b(c[7]),.sum(y[7]),.carry(c[8]));
    assign cout=c[8];
endmodule


