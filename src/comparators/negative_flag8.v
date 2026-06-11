// =====================================================================
//  negative_flag8.v
//  Negative flag, 8-bit (result MSB).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module negative_flag8(input [7:0] a, output neg);
    // define a input 80.160.255   // define neg output 255.255.255
    assign neg = a[7];
endmodule


