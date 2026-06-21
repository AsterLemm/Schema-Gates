// =====================================================================
//  add_end_around_carry8.v
//  8-bit end-around-carry adder.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_end_around_carry8(input [7:0] a, input [7:0] b, output [7:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define sum output 120.255.160
    // define cout output 255.120.120
    wire [8:0] ext = {1'b0,a} + {1'b0,b};
    wire [8:0] folded = ext[7:0] + ext[8];
    assign sum = folded[7:0];
    assign cout = folded[8];
endmodule


