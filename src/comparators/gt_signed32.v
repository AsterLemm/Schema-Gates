// =====================================================================
//  gt_signed32.v
//  Signed greater-than, 32-bit (two's complement).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gt_signed32(input signed [31:0] a, input signed [31:0] b, output y);
    // define a input 80.160.255
    // define b input 80.200.255
    // define y output 120.255.160
    assign y = (a >  b);
endmodule


