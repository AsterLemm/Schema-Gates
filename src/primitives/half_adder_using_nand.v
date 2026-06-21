// =====================================================================
//  half_adder_using_nand.v
//  Half adder using only NAND gates.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module half_adder_using_nand(input a, input b, output sum, output carry);
    wire t, t1, t2;
    assign t     = ~(a & b);
    assign t1    = ~(a & t);
    assign t2    = ~(b & t);
    assign sum   = ~(t1 & t2);
    assign carry = ~t;
endmodule


