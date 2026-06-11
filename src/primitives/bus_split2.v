// =====================================================================
//  bus_split2.v
//  Split a 2-bit bus into 2 single bits.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bus_split2(input [1:0] a, output o0, output o1);
    assign o0 = a[0];
    assign o1 = a[1];
endmodule


