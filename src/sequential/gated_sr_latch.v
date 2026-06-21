// =====================================================================
//  gated_sr_latch.v
//  Gated SR latch (level-sensitive).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gated_sr_latch(input s, input r, input en, output reg q);
    // define en input 255.180.80
    always @(*) if (en) begin if (s & ~r) q=1'b1; else if (r & ~s) q=1'b0; end
endmodule


