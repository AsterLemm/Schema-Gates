// =====================================================================
//  binary_to_excess15_4.v
//  4-bit value -> excess-15 (bias 15).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module binary_to_excess15_4(input [3:0] a, output [4:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y = {1'b0,a} + 5'd15;
endmodule


