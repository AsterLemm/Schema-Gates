// =====================================================================
//  add_carry_save32.v
//  32-bit carry-save adder (3-input -> sum/carry vectors, no ripple).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_carry_save32(input [31:0] a, input [31:0] b, input [31:0] cin_vec, output [31:0] s, output [31:0] c);
    // define a input 80.160.255   // define b input 80.200.255   // define cin_vec input 255.230.80
    // define s output 120.255.160   // define c output 255.120.120
    // Carry-save: per-bit full adders, no carry propagation between columns.
    full_adder fa0(.a(a[0]),.b(b[0]),.cin(cin_vec[0]),.sum(s[0]),.cout(c[0]));
    full_adder fa1(.a(a[1]),.b(b[1]),.cin(cin_vec[1]),.sum(s[1]),.cout(c[1]));
    full_adder fa2(.a(a[2]),.b(b[2]),.cin(cin_vec[2]),.sum(s[2]),.cout(c[2]));
    full_adder fa3(.a(a[3]),.b(b[3]),.cin(cin_vec[3]),.sum(s[3]),.cout(c[3]));
    full_adder fa4(.a(a[4]),.b(b[4]),.cin(cin_vec[4]),.sum(s[4]),.cout(c[4]));
    full_adder fa5(.a(a[5]),.b(b[5]),.cin(cin_vec[5]),.sum(s[5]),.cout(c[5]));
    full_adder fa6(.a(a[6]),.b(b[6]),.cin(cin_vec[6]),.sum(s[6]),.cout(c[6]));
    full_adder fa7(.a(a[7]),.b(b[7]),.cin(cin_vec[7]),.sum(s[7]),.cout(c[7]));
    full_adder fa8(.a(a[8]),.b(b[8]),.cin(cin_vec[8]),.sum(s[8]),.cout(c[8]));
    full_adder fa9(.a(a[9]),.b(b[9]),.cin(cin_vec[9]),.sum(s[9]),.cout(c[9]));
    full_adder fa10(.a(a[10]),.b(b[10]),.cin(cin_vec[10]),.sum(s[10]),.cout(c[10]));
    full_adder fa11(.a(a[11]),.b(b[11]),.cin(cin_vec[11]),.sum(s[11]),.cout(c[11]));
    full_adder fa12(.a(a[12]),.b(b[12]),.cin(cin_vec[12]),.sum(s[12]),.cout(c[12]));
    full_adder fa13(.a(a[13]),.b(b[13]),.cin(cin_vec[13]),.sum(s[13]),.cout(c[13]));
    full_adder fa14(.a(a[14]),.b(b[14]),.cin(cin_vec[14]),.sum(s[14]),.cout(c[14]));
    full_adder fa15(.a(a[15]),.b(b[15]),.cin(cin_vec[15]),.sum(s[15]),.cout(c[15]));
    full_adder fa16(.a(a[16]),.b(b[16]),.cin(cin_vec[16]),.sum(s[16]),.cout(c[16]));
    full_adder fa17(.a(a[17]),.b(b[17]),.cin(cin_vec[17]),.sum(s[17]),.cout(c[17]));
    full_adder fa18(.a(a[18]),.b(b[18]),.cin(cin_vec[18]),.sum(s[18]),.cout(c[18]));
    full_adder fa19(.a(a[19]),.b(b[19]),.cin(cin_vec[19]),.sum(s[19]),.cout(c[19]));
    full_adder fa20(.a(a[20]),.b(b[20]),.cin(cin_vec[20]),.sum(s[20]),.cout(c[20]));
    full_adder fa21(.a(a[21]),.b(b[21]),.cin(cin_vec[21]),.sum(s[21]),.cout(c[21]));
    full_adder fa22(.a(a[22]),.b(b[22]),.cin(cin_vec[22]),.sum(s[22]),.cout(c[22]));
    full_adder fa23(.a(a[23]),.b(b[23]),.cin(cin_vec[23]),.sum(s[23]),.cout(c[23]));
    full_adder fa24(.a(a[24]),.b(b[24]),.cin(cin_vec[24]),.sum(s[24]),.cout(c[24]));
    full_adder fa25(.a(a[25]),.b(b[25]),.cin(cin_vec[25]),.sum(s[25]),.cout(c[25]));
    full_adder fa26(.a(a[26]),.b(b[26]),.cin(cin_vec[26]),.sum(s[26]),.cout(c[26]));
    full_adder fa27(.a(a[27]),.b(b[27]),.cin(cin_vec[27]),.sum(s[27]),.cout(c[27]));
    full_adder fa28(.a(a[28]),.b(b[28]),.cin(cin_vec[28]),.sum(s[28]),.cout(c[28]));
    full_adder fa29(.a(a[29]),.b(b[29]),.cin(cin_vec[29]),.sum(s[29]),.cout(c[29]));
    full_adder fa30(.a(a[30]),.b(b[30]),.cin(cin_vec[30]),.sum(s[30]),.cout(c[30]));
    full_adder fa31(.a(a[31]),.b(b[31]),.cin(cin_vec[31]),.sum(s[31]),.cout(c[31]));
endmodule

module full_adder(input a, input b, input cin, output sum, output cout);
    wire s0, c0, c1;
    half_adder ha0(.a(a),  .b(b),   .sum(s0),  .carry(c0));
    half_adder ha1(.a(s0), .b(cin), .sum(sum), .carry(c1));
    assign cout = c0 | c1;
endmodule

module half_adder(input a, input b, output sum, output carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule


