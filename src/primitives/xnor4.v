// =====================================================================
//  xnor4.v
//  Basic gate: y = ~(a ^ b ^ c ^ d)
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module xnor4(input a, input b, input c, input d, output y);
    assign y = ~(a ^ b ^ c ^ d);
endmodule


