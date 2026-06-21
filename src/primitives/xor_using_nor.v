// =====================================================================
//  xor_using_nor.v
//  XOR from five NOR gates (verified network).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module xor_using_nor(input a, input b, output y);
    // verified 5-NOR XOR network
    wire na, nab, nb, t;
    assign na  = ~(a  | a);   // ~a
    assign nab = ~(a  | b);   // ~(a|b)
    assign nb  = ~(b  | b);   // ~b
    assign t   = ~(na | nb);  // ~(~a|~b) = a&b
    assign y   = ~(nab | t);  // a^b
endmodule


