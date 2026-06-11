// =====================================================================
//  dff_set_reset.v
//  D flip-flop with sync set & reset.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module dff_set_reset(input clk, input s, input r, input d, output reg q);
    always @(posedge clk) if (r) q<=1'b0; else if (s) q<=1'b1; else q<=d;
endmodule


