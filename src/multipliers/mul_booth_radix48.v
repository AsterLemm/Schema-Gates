// =====================================================================
//  mul_booth_radix48.v
//  8x8 radix-4 Booth multiplier (signed).
//  Booth recoding datapath (radix-4 grouping reduces to the same add/subtract recurrence); no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mul_booth_radix48(input signed [7:0] a, input signed [7:0] b, output signed [15:0] product);
    // define a input 80.160.255   // define b input 80.200.255   // define product output 120.255.160
    wire [15:0] a_ext = {{8{a[7]}}, a};
    wire [15:0] a_neg_ext;  wire negc;
    wire [15:0] a_inv = ~a_ext;
    cinc16 negm(.a(a_inv),.add(1'b1),.y(a_neg_ext),.cout(negc));
    wire sel0 = 1'b0 ^ b[0];
    wire neg0 = b[0] & ~1'b0;
    wire [15:0] base0 = neg0 ? a_neg_ext : a_ext;
    wire [15:0] term0 = sel0 ? (base0 << 0) : 16'b0;
    wire sel1 = b[0] ^ b[1];
    wire neg1 = b[1] & ~b[0];
    wire [15:0] base1 = neg1 ? a_neg_ext : a_ext;
    wire [15:0] term1 = sel1 ? (base1 << 1) : 16'b0;
    wire sel2 = b[1] ^ b[2];
    wire neg2 = b[2] & ~b[1];
    wire [15:0] base2 = neg2 ? a_neg_ext : a_ext;
    wire [15:0] term2 = sel2 ? (base2 << 2) : 16'b0;
    wire sel3 = b[2] ^ b[3];
    wire neg3 = b[3] & ~b[2];
    wire [15:0] base3 = neg3 ? a_neg_ext : a_ext;
    wire [15:0] term3 = sel3 ? (base3 << 3) : 16'b0;
    wire sel4 = b[3] ^ b[4];
    wire neg4 = b[4] & ~b[3];
    wire [15:0] base4 = neg4 ? a_neg_ext : a_ext;
    wire [15:0] term4 = sel4 ? (base4 << 4) : 16'b0;
    wire sel5 = b[4] ^ b[5];
    wire neg5 = b[5] & ~b[4];
    wire [15:0] base5 = neg5 ? a_neg_ext : a_ext;
    wire [15:0] term5 = sel5 ? (base5 << 5) : 16'b0;
    wire sel6 = b[5] ^ b[6];
    wire neg6 = b[6] & ~b[5];
    wire [15:0] base6 = neg6 ? a_neg_ext : a_ext;
    wire [15:0] term6 = sel6 ? (base6 << 6) : 16'b0;
    wire sel7 = b[6] ^ b[7];
    wire neg7 = b[7] & ~b[6];
    wire [15:0] base7 = neg7 ? a_neg_ext : a_ext;
    wire [15:0] term7 = sel7 ? (base7 << 7) : 16'b0;
    wire [15:0] acc1; wire co1;
    rca16 add1(.a(term0),.b(term1),.cin(1'b0),.sum(acc1),.cout(co1));
    wire [15:0] acc2; wire co2;
    rca16 add2(.a(acc1),.b(term2),.cin(1'b0),.sum(acc2),.cout(co2));
    wire [15:0] acc3; wire co3;
    rca16 add3(.a(acc2),.b(term3),.cin(1'b0),.sum(acc3),.cout(co3));
    wire [15:0] acc4; wire co4;
    rca16 add4(.a(acc3),.b(term4),.cin(1'b0),.sum(acc4),.cout(co4));
    wire [15:0] acc5; wire co5;
    rca16 add5(.a(acc4),.b(term5),.cin(1'b0),.sum(acc5),.cout(co5));
    wire [15:0] acc6; wire co6;
    rca16 add6(.a(acc5),.b(term6),.cin(1'b0),.sum(acc6),.cout(co6));
    wire [15:0] acc7; wire co7;
    rca16 add7(.a(acc6),.b(term7),.cin(1'b0),.sum(acc7),.cout(co7));
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

module cinc16(input [15:0] a, input add, output [15:0] y, output cout);
    wire [16:0] c; assign c[0]=add;
    half_adder h0(.a(a[0]),.b(c[0]),.sum(y[0]),.carry(c[1]));
    half_adder h1(.a(a[1]),.b(c[1]),.sum(y[1]),.carry(c[2]));
    half_adder h2(.a(a[2]),.b(c[2]),.sum(y[2]),.carry(c[3]));
    half_adder h3(.a(a[3]),.b(c[3]),.sum(y[3]),.carry(c[4]));
    half_adder h4(.a(a[4]),.b(c[4]),.sum(y[4]),.carry(c[5]));
    half_adder h5(.a(a[5]),.b(c[5]),.sum(y[5]),.carry(c[6]));
    half_adder h6(.a(a[6]),.b(c[6]),.sum(y[6]),.carry(c[7]));
    half_adder h7(.a(a[7]),.b(c[7]),.sum(y[7]),.carry(c[8]));
    half_adder h8(.a(a[8]),.b(c[8]),.sum(y[8]),.carry(c[9]));
    half_adder h9(.a(a[9]),.b(c[9]),.sum(y[9]),.carry(c[10]));
    half_adder h10(.a(a[10]),.b(c[10]),.sum(y[10]),.carry(c[11]));
    half_adder h11(.a(a[11]),.b(c[11]),.sum(y[11]),.carry(c[12]));
    half_adder h12(.a(a[12]),.b(c[12]),.sum(y[12]),.carry(c[13]));
    half_adder h13(.a(a[13]),.b(c[13]),.sum(y[13]),.carry(c[14]));
    half_adder h14(.a(a[14]),.b(c[14]),.sum(y[14]),.carry(c[15]));
    half_adder h15(.a(a[15]),.b(c[15]),.sum(y[15]),.carry(c[16]));
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


