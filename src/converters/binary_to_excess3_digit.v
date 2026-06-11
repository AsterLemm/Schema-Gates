// =====================================================================
//  binary_to_excess3_digit.v
//  BCD digit (0..9) -> excess-3 code.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module binary_to_excess3_digit(input [3:0] a, output [3:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y = a + 4'd3;
endmodule


