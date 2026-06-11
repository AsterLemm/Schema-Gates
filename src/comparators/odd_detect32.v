// =====================================================================
//  odd_detect32.v
//  Odd detect, 32-bit (LSB==1).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module odd_detect32(input [31:0] a, output y);
    // define a input 80.160.255   // define y output 255.255.255
    assign y = a[0];
endmodule


