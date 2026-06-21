// =====================================================================
//  or_using_nand.v
//  OR from three NANDs (invert inputs, NAND).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module or_using_nand(input a, input b, output y);
    wire na, nb;
    assign na = ~(a & a);
    assign nb = ~(b & b);
    assign y  = ~(na & nb);
endmodule


