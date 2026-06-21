// =====================================================================
//  excess3_to_binary_digit.v
//  Excess-3 -> BCD digit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module excess3_to_binary_digit(input [3:0] a, output [3:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y = a - 4'd3;
endmodule


