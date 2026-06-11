// =====================================================================
//  dff_negedge.v
//  Negative-edge D flip-flop.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module dff_negedge(input clk, input d, output reg q);
    always @(negedge clk) q <= d;
endmodule


