// =====================================================================
//  full_adder_using_nand.v
//  Full adder using only NAND gates.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module full_adder_using_nand(input a, input b, input cin, output sum, output cout);
    // first XOR (a^b)
    wire t, ab, x1, x2, axb;
    assign t   = ~(a & b);
    assign x1  = ~(a & t);
    assign x2  = ~(b & t);
    assign axb = ~(x1 & x2);     // a ^ b
    // second XOR ((a^b)^cin)
    wire u, y1, y2;
    assign u   = ~(axb & cin);
    assign y1  = ~(axb & u);
    assign y2  = ~(cin & u);
    assign sum = ~(y1 & y2);     // (a^b) ^ cin
    // carry = (a&b) | (cin&(a^b))  via NANDs
    assign cout = ~(t & u);
endmodule


