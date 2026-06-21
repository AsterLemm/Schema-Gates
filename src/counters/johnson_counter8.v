// =====================================================================
//  johnson_counter8.v
//  8-bit Johnson (twisted-ring) counter.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module johnson_counter8(input clk, input rst, output reg [7:0] q);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define q output 120.255.160
    always @(posedge clk) if (rst) q<=8'b0; else q<={q[6:0], ~q[7]};
endmodule


