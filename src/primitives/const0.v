// =====================================================================
//  const0.v
//  Constant logic 0.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module const0(output y);
    assign y = 1'b0;
endmodule


