// =====================================================================
//  add_ones_complement8.v
//  8-bit one's-complement adder (end-around carry).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_ones_complement8(input [7:0] a, input [7:0] b, output [7:0] sum);
    // define a input 80.160.255   // define b input 80.200.255   // define sum output 120.255.160
    wire [8:0] ext = {1'b0,a} + {1'b0,b};
    assign sum = ext[7:0] + ext[8];   // end-around carry
endmodule


