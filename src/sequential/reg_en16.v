// =====================================================================
//  reg_en16.v
//  16-bit register with enable.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module reg_en16(input clk, input en, input [15:0] d, output reg [15:0] q);
    // define clk input 255.230.80
    // define en input 255.180.80
    // define d input 80.160.255
    // define q output 120.255.160
    always @(posedge clk) if (en) q <= d;
endmodule


