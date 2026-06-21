// =====================================================================
//  bus_split8.v
//  Split a 8-bit bus into 8 single bits.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bus_split8(input [7:0] a, output o0, output o1, output o2, output o3, output o4, output o5, output o6, output o7);
    assign o0 = a[0];
    assign o1 = a[1];
    assign o2 = a[2];
    assign o3 = a[3];
    assign o4 = a[4];
    assign o5 = a[5];
    assign o6 = a[6];
    assign o7 = a[7];
endmodule


