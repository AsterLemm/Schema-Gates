// =====================================================================
//  not_using_nor.v
//  NOT built from one NOR (a NOR a).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module not_using_nor(input a, output y);
    assign y = ~(a | a);
endmodule


