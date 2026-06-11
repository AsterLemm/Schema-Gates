// =====================================================================
//  mul_booth_radix816.v
//  16x16 radix-8 Booth multiplier (signed).
//  Booth recoding datapath (radix-8 grouping reduces to the same add/subtract recurrence); no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mul_booth_radix816(input signed [15:0] a, input signed [15:0] b, output signed [31:0] product);
    // define a input 80.160.255   // define b input 80.200.255   // define product output 120.255.160
    wire [31:0] a_ext = {{16{a[15]}}, a};
    wire [31:0] a_neg_ext;  wire negc;
    wire [31:0] a_inv = ~a_ext;
    cinc32 negm(.a(a_inv),.add(1'b1),.y(a_neg_ext),.cout(negc));
    wire sel0 = 1'b0 ^ b[0];
    wire neg0 = b[0] & ~1'b0;
    wire [31:0] base0 = neg0 ? a_neg_ext : a_ext;
    wire [31:0] term0 = sel0 ? (base0 << 0) : 32'b0;
    wire sel1 = b[0] ^ b[1];
    wire neg1 = b[1] & ~b[0];
    wire [31:0] base1 = neg1 ? a_neg_ext : a_ext;
    wire [31:0] term1 = sel1 ? (base1 << 1) : 32'b0;
    wire sel2 = b[1] ^ b[2];
    wire neg2 = b[2] & ~b[1];
    wire [31:0] base2 = neg2 ? a_neg_ext : a_ext;
    wire [31:0] term2 = sel2 ? (base2 << 2) : 32'b0;
    wire sel3 = b[2] ^ b[3];
    wire neg3 = b[3] & ~b[2];
    wire [31:0] base3 = neg3 ? a_neg_ext : a_ext;
    wire [31:0] term3 = sel3 ? (base3 << 3) : 32'b0;
    wire sel4 = b[3] ^ b[4];
    wire neg4 = b[4] & ~b[3];
    wire [31:0] base4 = neg4 ? a_neg_ext : a_ext;
    wire [31:0] term4 = sel4 ? (base4 << 4) : 32'b0;
    wire sel5 = b[4] ^ b[5];
    wire neg5 = b[5] & ~b[4];
    wire [31:0] base5 = neg5 ? a_neg_ext : a_ext;
    wire [31:0] term5 = sel5 ? (base5 << 5) : 32'b0;
    wire sel6 = b[5] ^ b[6];
    wire neg6 = b[6] & ~b[5];
    wire [31:0] base6 = neg6 ? a_neg_ext : a_ext;
    wire [31:0] term6 = sel6 ? (base6 << 6) : 32'b0;
    wire sel7 = b[6] ^ b[7];
    wire neg7 = b[7] & ~b[6];
    wire [31:0] base7 = neg7 ? a_neg_ext : a_ext;
    wire [31:0] term7 = sel7 ? (base7 << 7) : 32'b0;
    wire sel8 = b[7] ^ b[8];
    wire neg8 = b[8] & ~b[7];
    wire [31:0] base8 = neg8 ? a_neg_ext : a_ext;
    wire [31:0] term8 = sel8 ? (base8 << 8) : 32'b0;
    wire sel9 = b[8] ^ b[9];
    wire neg9 = b[9] & ~b[8];
    wire [31:0] base9 = neg9 ? a_neg_ext : a_ext;
    wire [31:0] term9 = sel9 ? (base9 << 9) : 32'b0;
    wire sel10 = b[9] ^ b[10];
    wire neg10 = b[10] & ~b[9];
    wire [31:0] base10 = neg10 ? a_neg_ext : a_ext;
    wire [31:0] term10 = sel10 ? (base10 << 10) : 32'b0;
    wire sel11 = b[10] ^ b[11];
    wire neg11 = b[11] & ~b[10];
    wire [31:0] base11 = neg11 ? a_neg_ext : a_ext;
    wire [31:0] term11 = sel11 ? (base11 << 11) : 32'b0;
    wire sel12 = b[11] ^ b[12];
    wire neg12 = b[12] & ~b[11];
    wire [31:0] base12 = neg12 ? a_neg_ext : a_ext;
    wire [31:0] term12 = sel12 ? (base12 << 12) : 32'b0;
    wire sel13 = b[12] ^ b[13];
    wire neg13 = b[13] & ~b[12];
    wire [31:0] base13 = neg13 ? a_neg_ext : a_ext;
    wire [31:0] term13 = sel13 ? (base13 << 13) : 32'b0;
    wire sel14 = b[13] ^ b[14];
    wire neg14 = b[14] & ~b[13];
    wire [31:0] base14 = neg14 ? a_neg_ext : a_ext;
    wire [31:0] term14 = sel14 ? (base14 << 14) : 32'b0;
    wire sel15 = b[14] ^ b[15];
    wire neg15 = b[15] & ~b[14];
    wire [31:0] base15 = neg15 ? a_neg_ext : a_ext;
    wire [31:0] term15 = sel15 ? (base15 << 15) : 32'b0;
    wire [31:0] acc1; wire co1;
    rca32 add1(.a(term0),.b(term1),.cin(1'b0),.sum(acc1),.cout(co1));
    wire [31:0] acc2; wire co2;
    rca32 add2(.a(acc1),.b(term2),.cin(1'b0),.sum(acc2),.cout(co2));
    wire [31:0] acc3; wire co3;
    rca32 add3(.a(acc2),.b(term3),.cin(1'b0),.sum(acc3),.cout(co3));
    wire [31:0] acc4; wire co4;
    rca32 add4(.a(acc3),.b(term4),.cin(1'b0),.sum(acc4),.cout(co4));
    wire [31:0] acc5; wire co5;
    rca32 add5(.a(acc4),.b(term5),.cin(1'b0),.sum(acc5),.cout(co5));
    wire [31:0] acc6; wire co6;
    rca32 add6(.a(acc5),.b(term6),.cin(1'b0),.sum(acc6),.cout(co6));
    wire [31:0] acc7; wire co7;
    rca32 add7(.a(acc6),.b(term7),.cin(1'b0),.sum(acc7),.cout(co7));
    wire [31:0] acc8; wire co8;
    rca32 add8(.a(acc7),.b(term8),.cin(1'b0),.sum(acc8),.cout(co8));
    wire [31:0] acc9; wire co9;
    rca32 add9(.a(acc8),.b(term9),.cin(1'b0),.sum(acc9),.cout(co9));
    wire [31:0] acc10; wire co10;
    rca32 add10(.a(acc9),.b(term10),.cin(1'b0),.sum(acc10),.cout(co10));
    wire [31:0] acc11; wire co11;
    rca32 add11(.a(acc10),.b(term11),.cin(1'b0),.sum(acc11),.cout(co11));
    wire [31:0] acc12; wire co12;
    rca32 add12(.a(acc11),.b(term12),.cin(1'b0),.sum(acc12),.cout(co12));
    wire [31:0] acc13; wire co13;
    rca32 add13(.a(acc12),.b(term13),.cin(1'b0),.sum(acc13),.cout(co13));
    wire [31:0] acc14; wire co14;
    rca32 add14(.a(acc13),.b(term14),.cin(1'b0),.sum(acc14),.cout(co14));
    wire [31:0] acc15; wire co15;
    rca32 add15(.a(acc14),.b(term15),.cin(1'b0),.sum(acc15),.cout(co15));
    assign product = acc15;
endmodule

module rca32(input [31:0] a, input [31:0] b, input cin, output [31:0] sum, output cout);
    wire [32:0] c; assign c[0]=cin;
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
    full_adder fa16(.a(a[16]),.b(b[16]),.cin(c[16]),.sum(sum[16]),.cout(c[17]));
    full_adder fa17(.a(a[17]),.b(b[17]),.cin(c[17]),.sum(sum[17]),.cout(c[18]));
    full_adder fa18(.a(a[18]),.b(b[18]),.cin(c[18]),.sum(sum[18]),.cout(c[19]));
    full_adder fa19(.a(a[19]),.b(b[19]),.cin(c[19]),.sum(sum[19]),.cout(c[20]));
    full_adder fa20(.a(a[20]),.b(b[20]),.cin(c[20]),.sum(sum[20]),.cout(c[21]));
    full_adder fa21(.a(a[21]),.b(b[21]),.cin(c[21]),.sum(sum[21]),.cout(c[22]));
    full_adder fa22(.a(a[22]),.b(b[22]),.cin(c[22]),.sum(sum[22]),.cout(c[23]));
    full_adder fa23(.a(a[23]),.b(b[23]),.cin(c[23]),.sum(sum[23]),.cout(c[24]));
    full_adder fa24(.a(a[24]),.b(b[24]),.cin(c[24]),.sum(sum[24]),.cout(c[25]));
    full_adder fa25(.a(a[25]),.b(b[25]),.cin(c[25]),.sum(sum[25]),.cout(c[26]));
    full_adder fa26(.a(a[26]),.b(b[26]),.cin(c[26]),.sum(sum[26]),.cout(c[27]));
    full_adder fa27(.a(a[27]),.b(b[27]),.cin(c[27]),.sum(sum[27]),.cout(c[28]));
    full_adder fa28(.a(a[28]),.b(b[28]),.cin(c[28]),.sum(sum[28]),.cout(c[29]));
    full_adder fa29(.a(a[29]),.b(b[29]),.cin(c[29]),.sum(sum[29]),.cout(c[30]));
    full_adder fa30(.a(a[30]),.b(b[30]),.cin(c[30]),.sum(sum[30]),.cout(c[31]));
    full_adder fa31(.a(a[31]),.b(b[31]),.cin(c[31]),.sum(sum[31]),.cout(c[32]));
    assign cout=c[32];
endmodule

module cinc32(input [31:0] a, input add, output [31:0] y, output cout);
    wire [32:0] c; assign c[0]=add;
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
    half_adder h16(.a(a[16]),.b(c[16]),.sum(y[16]),.carry(c[17]));
    half_adder h17(.a(a[17]),.b(c[17]),.sum(y[17]),.carry(c[18]));
    half_adder h18(.a(a[18]),.b(c[18]),.sum(y[18]),.carry(c[19]));
    half_adder h19(.a(a[19]),.b(c[19]),.sum(y[19]),.carry(c[20]));
    half_adder h20(.a(a[20]),.b(c[20]),.sum(y[20]),.carry(c[21]));
    half_adder h21(.a(a[21]),.b(c[21]),.sum(y[21]),.carry(c[22]));
    half_adder h22(.a(a[22]),.b(c[22]),.sum(y[22]),.carry(c[23]));
    half_adder h23(.a(a[23]),.b(c[23]),.sum(y[23]),.carry(c[24]));
    half_adder h24(.a(a[24]),.b(c[24]),.sum(y[24]),.carry(c[25]));
    half_adder h25(.a(a[25]),.b(c[25]),.sum(y[25]),.carry(c[26]));
    half_adder h26(.a(a[26]),.b(c[26]),.sum(y[26]),.carry(c[27]));
    half_adder h27(.a(a[27]),.b(c[27]),.sum(y[27]),.carry(c[28]));
    half_adder h28(.a(a[28]),.b(c[28]),.sum(y[28]),.carry(c[29]));
    half_adder h29(.a(a[29]),.b(c[29]),.sum(y[29]),.carry(c[30]));
    half_adder h30(.a(a[30]),.b(c[30]),.sum(y[30]),.carry(c[31]));
    half_adder h31(.a(a[31]),.b(c[31]),.sum(y[31]),.carry(c[32]));
    assign cout=c[32];
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


