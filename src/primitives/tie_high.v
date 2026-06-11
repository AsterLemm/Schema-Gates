// =====================================================================
//  tie_high.v
//  Tie-high cell (drives 1).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module tie_high(output y);
    assign y = 1'b1;
endmodule


