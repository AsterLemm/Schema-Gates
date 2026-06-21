// =====================================================================
//  reg12.v
//  12-bit register.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module reg12(input clk, input [11:0] d, output reg [11:0] q);
    // define clk input 255.230.80
    // define d input 80.160.255
    // define q output 120.255.160
    always @(posedge clk) q <= d;
endmodule


