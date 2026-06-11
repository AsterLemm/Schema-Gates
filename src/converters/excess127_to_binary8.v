// =====================================================================
//  excess127_to_binary8.v
//  Excess-127 -> 8-bit value.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module excess127_to_binary8(input [8:0] a, output [7:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y = a - 9'd127;
endmodule


