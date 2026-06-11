// =====================================================================
//  add_saturating_unsigned4.v
//  4-bit unsigned saturating add (clamps to max).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_saturating_unsigned4(input [3:0] a, input [3:0] b, output [3:0] sum);
    // define a input 80.160.255   // define b input 80.200.255   // define sum output 120.255.160
    wire [4:0] ext = {1'b0,a} + {1'b0,b};
    assign sum = ext[4] ? {4{1'b1}} : ext[3:0];
endmodule


