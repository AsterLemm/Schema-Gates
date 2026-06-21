// =====================================================================
//  mod_signed4.v
//  4-bit signed modulo.
//  Structural signed restoring array; no / or % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mod_signed4(input signed [3:0] a, input signed [3:0] b, output signed [3:0] remainder, output divide_by_zero, output valid, output busy, output done);
    // define a input 80.160.255
    // define b input 80.200.255
    // define remainder output 120.255.160
    wire dz=~(|b);
    wire [3:0] q_unused, r;
    wire d2,o2,v2,b2,dn2;
    div_sgncore4 dv(.a(a),.b(b),.quotient(q_unused),.remainder(r),.divide_by_zero(d2),.overflow(o2),.valid(v2),.busy(b2),.done(dn2));
    assign remainder = dz ? a : r;
    assign divide_by_zero=dz; assign valid=~dz; assign busy=1'b0; assign done=1'b1;
endmodule

module div_sgncore4(input signed [3:0] a, input signed [3:0] b,
    output signed [3:0] quotient, output signed [3:0] remainder,
    output divide_by_zero, output overflow, output valid, output busy, output done);
    wire dz = ~(|b);
    wire sa=a[3], sb=b[3];
    wire [3:0] mag_a, mag_b; wire ca,cb;
    wire [3:0] ai = a ^ {4{sa}}, bi = b ^ {4{sb}};
    cincd4 na(.a(ai),.add(sa),.y(mag_a),.cout(ca));
    cincd4 nb(.a(bi),.add(sb),.y(mag_b),.cout(cb));
    wire [3:0] uq, ur; wire udz,uov,uv,ub,ud;
    udivcore4 dv(.a(mag_a),.b(mag_b),.quotient(uq),.remainder(ur),
        .divide_by_zero(udz),.overflow(uov),.valid(uv),.busy(ub),.done(ud));
    wire qs = sa ^ sb;
    wire [3:0] uq_i = uq ^ {4{qs}}; wire [3:0] q_fixed; wire qc;
    cincd4 fq(.a(uq_i),.add(qs),.y(q_fixed),.cout(qc));
    wire [3:0] ur_i = ur ^ {4{sa}}; wire [3:0] r_fixed; wire rc;
    cincd4 fr(.a(ur_i),.add(sa),.y(r_fixed),.cout(rc));
    assign quotient  = dz ? {4{1'b1}} : q_fixed;
    assign remainder = dz ? a : r_fixed;
    assign overflow = 1'b0; assign valid=~dz; assign busy=1'b0; assign done=1'b1;
endmodule

module udivcore4(input [3:0] a, input [3:0] b,
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

module cincd4(input [3:0] a, input add, output [3:0] y, output cout);
    wire [4:0] c; assign c[0]=add;
    half_adder h0(.a(a[0]),.b(c[0]),.sum(y[0]),.carry(c[1]));
    half_adder h1(.a(a[1]),.b(c[1]),.sum(y[1]),.carry(c[2]));
    half_adder h2(.a(a[2]),.b(c[2]),.sum(y[2]),.carry(c[3]));
    half_adder h3(.a(a[3]),.b(c[3]),.sum(y[3]),.carry(c[4]));
    assign cout=c[4];
endmodule


