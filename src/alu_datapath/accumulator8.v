// =====================================================================
//  accumulator8.v
//  8-bit accumulator register.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module accumulator8(input clk, input rst, input en, input [7:0] din, output reg [7:0] acc);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define en input 255.180.80
    // define din input 80.160.255
    // define acc output 120.255.160
    always @(posedge clk) if (rst) acc<=8'b0; else if (en) acc<=din;
endmodule


