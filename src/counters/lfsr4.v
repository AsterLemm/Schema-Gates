// =====================================================================
//  lfsr4.v
//  4-bit Fibonacci LFSR (maximal-length taps).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module lfsr4(input clk, input rst, input en, output reg [3:0] q);
    // define clk input 255.230.80   // define rst input 255.80.80   // define en input 255.180.80
    // define q output 120.255.160
    wire fb = q[3] ^ q[2];
    always @(posedge clk) if (rst) q<=4'b1; else if (en) q<={q[2:0], fb};
endmodule


