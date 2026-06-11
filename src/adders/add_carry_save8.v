// =====================================================================
//  add_carry_save8.v
//  8-bit carry-save adder (3-input -> sum/carry vectors, no ripple).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_carry_save8(input [7:0] a, input [7:0] b, input [7:0] cin_vec, output [7:0] s, output [7:0] c);
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


