// =====================================================================
//  lte_unsigned4.v
//  Unsigned less-or-equal, 4-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module lte_unsigned4(input [3:0] a, input [3:0] b, output y);
    // define a input 80.160.255
    // define b input 80.200.255
    // define y output 120.255.160
    assign y = (a <= b);
endmodule


