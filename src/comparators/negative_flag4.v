// =====================================================================
//  negative_flag4.v
//  Negative flag, 4-bit (result MSB).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module negative_flag4(input [3:0] a, output neg);
    // define a input 80.160.255   // define neg output 255.255.255
    assign neg = a[3];
endmodule


