// =====================================================================
//  reg_reset12.v
//  12-bit register, sync reset + enable.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module reg_reset12(input clk, input rst, input en, input [11:0] d, output reg [11:0] q);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define en input 255.180.80
    // define d input 80.160.255
    // define q output 120.255.160
    always @(posedge clk) if (rst) q <= 12'b0; else if (en) q <= d;
endmodule


