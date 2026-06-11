// =====================================================================
//  neq4.v
//  Inequality, 4-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module neq4(input [3:0] a, input [3:0] b, output neq);
    // define a input 80.160.255   // define b input 80.200.255
    // define neq output 120.255.160
    assign neq = (a != b);
endmodule


