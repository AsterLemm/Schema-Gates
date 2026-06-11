// =====================================================================
//  gray_counter16.v
//  16-bit Gray-code counter.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gray_counter16(input clk, input rst, input en, output [15:0] gray);
    // define clk input 255.230.80   // define rst input 255.80.80   // define en input 255.180.80
    // define gray output 120.255.160
    reg [15:0] bin;
    always @(posedge clk) if (rst) bin<=16'b0; else if (en) bin<=bin+1'b1;
    assign gray = bin ^ (bin >> 1);
endmodule


