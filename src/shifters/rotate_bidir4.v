// =====================================================================
//  rotate_bidir4.v
//  4-bit bidirectional rotate.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rotate_bidir4(input [3:0] a, input [1:0] sh, input dir, output [3:0] y);
    // define a input 80.160.255
    // define sh input 200.120.255
    // define dir input 200.120.255
    // define y output 120.255.160
    wire [3:0] rl = (a << sh) | (a >> (4-sh));
    wire [3:0] rr = (a >> sh) | (a << (4-sh));
    assign y = dir ? rr : rl;
endmodule


