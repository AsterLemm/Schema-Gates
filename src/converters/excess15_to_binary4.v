// =====================================================================
//  excess15_to_binary4.v
//  Excess-15 -> 4-bit value.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module excess15_to_binary4(input [4:0] a, output [3:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y = a - 5'd15;
endmodule


