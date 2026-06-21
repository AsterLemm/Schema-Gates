// =====================================================================
//  bus_join8.v
//  Join 8 single bits into a 8-bit bus (i7=MSB).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bus_join8(input i0, input i1, input i2, input i3, input i4, input i5, input i6, input i7, output [7:0] y);
    assign y = {i7, i6, i5, i4, i3, i2, i1, i0};
endmodule


