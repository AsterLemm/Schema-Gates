// =====================================================================
//  bin_to_ascii_digit.v
//  4-bit hex nibble to ASCII character code.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_ascii_digit(input [3:0] a, output [7:0] ascii);
    // define a input 80.160.255   // define ascii output 120.255.160
    // 0-9 -> '0'..'9', a-f -> 'A'..'F'
    assign ascii = (a < 10) ? (8'h30 + a) : (8'h41 + (a - 10));
endmodule


