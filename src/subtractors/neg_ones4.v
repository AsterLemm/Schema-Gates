// =====================================================================
//  neg_ones4.v
//  4-bit one's-complement negate (y = ~a).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module neg_ones4(input [3:0] a, output [3:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y = ~a;            // one's complement
endmodule


