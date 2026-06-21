// =====================================================================
//  min2_8.v
//  8-bit 2-input minimum.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module min2_8(input [7:0] a, input [7:0] b, output [7:0] y);
    // define a input 80.160.255
    // define b input 80.200.255
    // define y output 120.255.160
    assign y = (a < b) ? a : b;
endmodule


