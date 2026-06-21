// =====================================================================
//  half_adder_using_nor.v
//  Half adder using only NOR gates (verified).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module half_adder_using_nor(input a, input b, output sum, output carry);
    // sum = a^b (5-NOR), carry = a&b = NOR(~a,~b)
    wire na, nab, nb, t;
    assign na    = ~(a  | a);
    assign nab   = ~(a  | b);
    assign nb    = ~(b  | b);
    assign t     = ~(na | nb);   // a & b
    assign sum   = ~(nab | t);   // a ^ b
    assign carry = t;            // a & b
endmodule


