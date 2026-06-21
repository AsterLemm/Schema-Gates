// =====================================================================
//  rotate_bidir16.v
//  16-bit bidirectional rotate.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rotate_bidir16(input [15:0] a, input [3:0] sh, input dir, output [15:0] y);
    // define a input 80.160.255
    // define sh input 200.120.255
    // define dir input 200.120.255
    // define y output 120.255.160
    wire [15:0] rl = (a << sh) | (a >> (16-sh));
    wire [15:0] rr = (a >> sh) | (a << (16-sh));
    assign y = dir ? rr : rl;
endmodule


