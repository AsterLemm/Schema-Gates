// =====================================================================
//  not_using_nand.v
//  NOT built from one NAND (a NAND a).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module not_using_nand(input a, output y);
    assign y = ~(a & a);
endmodule


