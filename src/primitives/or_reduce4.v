// =====================================================================
//  or_reduce4.v
//  OR-reduce: 1 iff any bit set.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module or_reduce4(input [3:0] a, output y);
    assign y = |a;
endmodule


