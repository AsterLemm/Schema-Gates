// =====================================================================
//  compressor4to2.v
//  4:2 compressor.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module compressor4to2(input a, input b, input c, input d, input cin, output sum, output carry, output cout);
    wire s0,c0;
    assign s0   = a ^ b ^ c;
    assign c0   = (a&b)|(b&c)|(a&c);
    assign sum  = s0 ^ d ^ cin;
    assign carry= (s0&d)|(d&cin)|(s0&cin);
    assign cout = c0;
endmodule


