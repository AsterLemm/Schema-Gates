// =====================================================================
//  gte_signed8.v
//  Signed greater-or-equal, 8-bit (two's complement).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gte_signed8(input signed [7:0] a, input signed [7:0] b, output y);
    // define a input 80.160.255   // define b input 80.200.255
    // define y output 120.255.160
    assign y = (a >= b);
endmodule


