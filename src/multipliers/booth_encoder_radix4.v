// =====================================================================
//  booth_encoder_radix4.v
//  Radix-4 modified-Booth encoder cell.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module booth_encoder_radix4(input b_hi, input b_mid, input b_lo, output neg, output one, output two);
    // define b_hi input 80.160.255   // define neg output 255.120.120   // define one output 120.255.160   // define two output 120.255.160
    // radix-4 modified Booth digit from {b_(2i+1), b_2i, b_(2i-1)}
    assign neg = b_hi;
    assign one = b_mid ^ b_lo;            // |digit| == 1
    assign two = (b_hi & ~b_mid & ~b_lo) | (~b_hi & b_mid & b_lo); // |digit| == 2
endmodule


