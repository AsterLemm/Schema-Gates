// =====================================================================
//  bcd_valid4.v
//  4-digit BCD validity (each nibble <= 9).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_valid4(input [15:0] a, output valid);
    // define a input 80.160.255   // define valid output 255.255.255
    assign valid = (a[3:0] <= 9) & (a[7:4] <= 9) & (a[11:8] <= 9) & (a[15:12] <= 9);
endmodule


