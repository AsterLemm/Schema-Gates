// =====================================================================
//  sign_detect16.v
//  Sign detect, 16-bit (MSB).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sign_detect16(input [15:0] a, output y);
    // define a input 80.160.255   // define y output 255.255.255
    assign y = a[15];
endmodule


