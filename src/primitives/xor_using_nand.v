// =====================================================================
//  xor_using_nand.v
//  XOR from four NANDs (classic 4-gate form).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module xor_using_nand(input a, input b, output y);
    wire t, t1, t2;
    assign t  = ~(a & b);
    assign t1 = ~(a & t);
    assign t2 = ~(b & t);
    assign y  = ~(t1 & t2);
endmodule


