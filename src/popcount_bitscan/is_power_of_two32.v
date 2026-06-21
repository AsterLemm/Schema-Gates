// =====================================================================
//  is_power_of_two32.v
//  32-bit power-of-two detector.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module is_power_of_two32(input [31:0] a, output y);
    // define a input 80.160.255
    // define y output 255.255.255
    assign y = (|a) & ~(|(a & (a - 1'b1)));
endmodule


