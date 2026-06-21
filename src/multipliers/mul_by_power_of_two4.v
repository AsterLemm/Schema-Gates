// =====================================================================
//  mul_by_power_of_two4.v
//  4-bit multiply by 2^shift (shift only).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mul_by_power_of_two4(input [3:0] a, input [2:0] shift, output [7:0] y);
    // define a input 80.160.255
    // define shift input 200.120.255
    // define y output 120.255.160
    assign y = {{4{1'b0}}, a} << shift;   // shift = wiring/barrel; no multiply
endmodule


