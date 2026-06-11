// =====================================================================
//  tie_low.v
//  Tie-low cell (drives 0).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module tie_low(output y);
    assign y = 1'b0;
endmodule


