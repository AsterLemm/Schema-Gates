// =====================================================================
//  add_end_around_carry16.v
//  16-bit end-around-carry adder.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_end_around_carry16(input [15:0] a, input [15:0] b, output [15:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define sum output 120.255.160
    // define cout output 255.120.120
    wire [16:0] ext = {1'b0,a} + {1'b0,b};
    wire [16:0] folded = ext[15:0] + ext[16];
    assign sum = folded[15:0];
    assign cout = folded[16];
endmodule


