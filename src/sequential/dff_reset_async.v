// =====================================================================
//  dff_reset_async.v
//  D flip-flop, asynchronous reset.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module dff_reset_async(input clk, input rst, input d, output reg q);
    always @(posedge clk or posedge rst) if (rst) q <= 1'b0; else q <= d;
endmodule


