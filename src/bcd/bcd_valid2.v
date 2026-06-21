// =====================================================================
//  bcd_valid2.v
//  2-digit BCD validity (each nibble <= 9).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_valid2(input [7:0] a, output valid);
    // define a input 80.160.255
    // define valid output 255.255.255
    assign valid = (a[3:0] <= 9) & (a[7:4] <= 9);
endmodule


