// =====================================================================
//  buf1.v
//  Basic gate: y = a
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module buf1(input a, output y);
    assign y = a;
endmodule


