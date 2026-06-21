// =====================================================================
//  min2_16.v
//  16-bit 2-input minimum.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module min2_16(input [15:0] a, input [15:0] b, output [15:0] y);
    // define a input 80.160.255
    // define b input 80.200.255
    // define y output 120.255.160
    assign y = (a < b) ? a : b;
endmodule


