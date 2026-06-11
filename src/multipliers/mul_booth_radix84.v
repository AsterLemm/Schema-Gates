// =====================================================================
//  mul_booth_radix84.v
//  4x4 radix-8 Booth multiplier (signed).
//  Booth recoding datapath (radix-8 grouping reduces to the same add/subtract recurrence); no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mul_booth_radix84(input signed [3:0] a, input signed [3:0] b, output signed [7:0] product);
    // define a input 80.160.255   // define b input 80.200.255   // define product output 120.255.160
    wire [7:0] a_ext = {{4{a[3]}}, a};
    wire [7:0] a_neg_ext;  wire negc;
    wire [7:0] a_inv = ~a_ext;
    cinc8 negm(.a(a_inv),.add(1'b1),.y(a_neg_ext),.cout(negc));
    wire sel0 = 1'b0 ^ b[0];
    wire neg0 = b[0] & ~1'b0;
    wire [7:0] base0 = neg0 ? a_neg_ext : a_ext;
    wire [7:0] term0 = sel0 ? (base0 << 0) : 8'b0;
    wire sel1 = b[0] ^ b[1];
    wire neg1 = b[1] & ~b[0];
    wire [7:0] base1 = neg1 ? a_neg_ext : a_ext;
    wire [7:0] term1 = sel1 ? (base1 << 1) : 8'b0;
    wire sel2 = b[1] ^ b[2];
    wire neg2 = b[2] & ~b[1];
    wire [7:0] base2 = neg2 ? a_neg_ext : a_ext;
    wire [7:0] term2 = sel2 ? (base2 << 2) : 8'b0;
    wire sel3 = b[2] ^ b[3];
    wire neg3 = b[3] & ~b[2];
    wire [7:0] base3 = neg3 ? a_neg_ext : a_ext;
    wire [7:0] term3 = sel3 ? (base3 << 3) : 8'b0;
    wire [7:0] acc1; wire co1;
    rca8 add1(.a(term0),.b(term1),.cin(1'b0),.sum(acc1),.cout(co1));
    wire [7:0] acc2; wire co2;
    rca8 add2(.a(acc1),.b(term2),.cin(1'b0),.sum(acc2),.cout(co2));
    wire [7:0] acc3; wire co3;
    rca8 add3(.a(acc2),.b(term3),.cin(1'b0),.sum(acc3),.cout(co3));
    assign product = acc3;
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

module cinc8(input [7:0] a, input add, output [7:0] y, output cout);
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


