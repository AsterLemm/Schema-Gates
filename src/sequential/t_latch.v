// =====================================================================
//  t_latch.v
//  T (toggle) latch.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module t_latch(input t, input en, output reg q);
    always @(*) if (en && t) q=~q;
endmodule


