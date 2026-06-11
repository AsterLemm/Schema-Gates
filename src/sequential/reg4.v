// =====================================================================
//  reg4.v
//  4-bit register.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module reg4(input clk, input [3:0] d, output reg [3:0] q);
    // define clk input 255.230.80   // define d input 80.160.255   // define q output 120.255.160
    always @(posedge clk) q <= d;
endmodule


