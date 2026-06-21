// =====================================================================
//  negative_flag16.v
//  Negative flag, 16-bit (result MSB).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module negative_flag16(input [15:0] a, output neg);
    // define a input 80.160.255
    // define neg output 255.255.255
    assign neg = a[15];
endmodule


