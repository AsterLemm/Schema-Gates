// =====================================================================
//  add_rc8.v
//  8-bit ripple-carry adder (two add_rc4 chained on midpoint carry).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_rc8(input [7:0] a, input [7:0] b, input cin, output [7:0] sum, output cout);
    // define a input 80.160.255   // define b input 80.200.255
    // define cin input 255.230.80   // define sum output 120.255.160   // define cout output 255.120.120
    wire cmid;
    add_rc4 lo(.a(a[3:0]),    .b(b[3:0]),    .cin(cin),  .sum(sum[3:0]),    .cout(cmid));
    add_rc4 hi(.a(a[7:4]),  .b(b[7:4]),  .cin(cmid), .sum(sum[7:4]),  .cout(cout));
endmodule

module add_rc4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    // define a input 80.160.255   // define b input 80.200.255
    // define cin input 255.230.80   // define sum output 120.255.160   // define cout output 255.120.120
    wire c0,c1,c2;
    full_adder fa0(.a(a[0]),.b(b[0]),.cin(cin),.sum(sum[0]),.cout(c0));
    full_adder fa1(.a(a[1]),.b(b[1]),.cin(c0), .sum(sum[1]),.cout(c1));
    full_adder fa2(.a(a[2]),.b(b[2]),.cin(c1), .sum(sum[2]),.cout(c2));
    full_adder fa3(.a(a[3]),.b(b[3]),.cin(c2), .sum(sum[3]),.cout(cout));
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


