// =====================================================================
//  booth_encoder_radix2.v
//  Radix-2 Booth encoder cell (sel/neg from bit pair).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module booth_encoder_radix2(input b_i, input b_im1, output neg, output sel);
    // define b_i input 80.160.255   // define b_im1 input 80.200.255   // define neg output 255.120.120   // define sel output 120.255.160
    assign sel = b_i ^ b_im1;   // nonzero Booth digit
    assign neg = b_i & ~b_im1;  // negative (-1) digit
endmodule


