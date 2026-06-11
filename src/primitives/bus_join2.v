// =====================================================================
//  bus_join2.v
//  Join 2 single bits into a 2-bit bus (i1=MSB).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bus_join2(input i0, input i1, output [1:0] y);
    assign y = {i1, i0};
endmodule


