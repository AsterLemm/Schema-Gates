// =====================================================================
//  rotate_left16.v
//  16-bit rotate left.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rotate_left16(input [15:0] a, input [3:0] sh, output [15:0] y);
    // define a input 80.160.255   // define sh input 200.120.255   // define y output 120.255.160
    assign y = (a << sh) | (a >> (16-sh));
endmodule


