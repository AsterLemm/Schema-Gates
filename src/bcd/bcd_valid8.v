// =====================================================================
//  bcd_valid8.v
//  8-digit BCD validity (each nibble <= 9).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_valid8(input [31:0] a, output valid);
    // define a input 80.160.255   // define valid output 255.255.255
    assign valid = (a[3:0] <= 9) & (a[7:4] <= 9) & (a[11:8] <= 9) & (a[15:12] <= 9) & (a[19:16] <= 9) & (a[23:20] <= 9) & (a[27:24] <= 9) & (a[31:28] <= 9);
endmodule


