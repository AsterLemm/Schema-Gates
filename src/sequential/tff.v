// =====================================================================
//  tff.v
//  T (toggle) flip-flop.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module tff(input clk, input t, output reg q);
    always @(posedge clk) if (t) q<=~q;
endmodule


