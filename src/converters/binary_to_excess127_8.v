// =====================================================================
//  binary_to_excess127_8.v
//  8-bit value -> excess-127 (float-exponent style bias).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module binary_to_excess127_8(input [7:0] a, output [8:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y = {1'b0,a} + 9'd127;
endmodule


