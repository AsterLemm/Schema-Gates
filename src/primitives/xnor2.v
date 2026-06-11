// =====================================================================
//  xnor2.v
//  Basic gate: y = ~(a ^ b)
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module xnor2(input a, input b, output y);
    assign y = ~(a ^ b);
endmodule


