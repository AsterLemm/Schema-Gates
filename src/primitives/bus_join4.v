// =====================================================================
//  bus_join4.v
//  Join 4 single bits into a 4-bit bus (i3=MSB).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bus_join4(input i0, input i1, input i2, input i3, output [3:0] y);
    assign y = {i3, i2, i1, i0};
endmodule


