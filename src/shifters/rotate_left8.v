// =====================================================================
//  rotate_left8.v
//  8-bit rotate left.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rotate_left8(input [7:0] a, input [2:0] sh, output [7:0] y);
    // define a input 80.160.255
    // define sh input 200.120.255
    // define y output 120.255.160
    assign y = (a << sh) | (a >> (8-sh));
endmodule


