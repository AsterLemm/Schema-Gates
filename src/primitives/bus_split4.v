// =====================================================================
//  bus_split4.v
//  Split a 4-bit bus into 4 single bits.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bus_split4(input [3:0] a, output o0, output o1, output o2, output o3);
    assign o0 = a[0];
    assign o1 = a[1];
    assign o2 = a[2];
    assign o3 = a[3];
endmodule


