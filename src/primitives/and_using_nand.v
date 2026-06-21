// =====================================================================
//  and_using_nand.v
//  AND from two NANDs (NAND then invert).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module and_using_nand(input a, input b, output y);
    wire t;
    assign t = ~(a & b);
    assign y = ~(t & t);
endmodule


