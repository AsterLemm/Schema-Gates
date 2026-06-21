// =====================================================================
//  add_ones_complement32.v
//  32-bit one's-complement adder (end-around carry).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_ones_complement32(input [31:0] a, input [31:0] b, output [31:0] sum);
    // define a input 80.160.255
    // define b input 80.200.255
    // define sum output 120.255.160
    wire [32:0] ext = {1'b0,a} + {1'b0,b};
    assign sum = ext[31:0] + ext[32];   // end-around carry
endmodule


