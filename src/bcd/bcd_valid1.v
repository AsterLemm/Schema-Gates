// =====================================================================
//  bcd_valid1.v
//  1-digit BCD validity (each nibble <= 9).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_valid1(input [3:0] a, output valid);
    // define a input 80.160.255
    // define valid output 255.255.255
    assign valid = (a[3:0] <= 9);
endmodule


