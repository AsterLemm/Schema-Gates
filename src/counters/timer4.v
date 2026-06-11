// =====================================================================
//  timer4.v
//  4-bit programmable timer.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module timer4(input clk, input rst, input en, input [3:0] period, output reg [3:0] count, output expired);
    // define clk input 255.230.80   // define rst input 255.80.80   // define en input 255.180.80
    // define period input 80.160.255   // define count output 120.255.160   // define expired output 255.255.255
    assign expired = (count == period);
    always @(posedge clk) if (rst) count<=4'b0; else if (en) count <= expired ? 4'b0 : count+1'b1;
endmodule


