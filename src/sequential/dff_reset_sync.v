// =====================================================================
//  dff_reset_sync.v
//  D flip-flop, synchronous reset.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module dff_reset_sync(input clk, input rst, input d, output reg q);
    // define clk input 255.230.80   // define rst input 255.80.80   // define en input 255.180.80
    always @(posedge clk) if (rst) q <= 1'b0; else q <= d;
endmodule


