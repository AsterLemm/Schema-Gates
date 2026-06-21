// =====================================================================
//  d_latch_en.v
//  D latch with explicit enable.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module d_latch_en(input d, input en, output reg q);
    always @(*) if (en) q = d;
endmodule


