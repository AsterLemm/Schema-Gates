// =====================================================================
//  lfsr8.v
//  8-bit Fibonacci LFSR (maximal-length taps).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module lfsr8(input clk, input rst, input en, output reg [7:0] q);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define en input 255.180.80
    // define q output 120.255.160
    wire fb = q[7] ^ q[5] ^ q[4] ^ q[3];
    always @(posedge clk) if (rst) q<=8'b1; else if (en) q<={q[6:0], fb};
endmodule


