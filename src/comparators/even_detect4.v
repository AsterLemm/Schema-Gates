// =====================================================================
//  even_detect4.v
//  Even detect, 4-bit (LSB==0).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module even_detect4(input [3:0] a, output y);
    // define a input 80.160.255   // define y output 255.255.255
    assign y = ~a[0];
endmodule


