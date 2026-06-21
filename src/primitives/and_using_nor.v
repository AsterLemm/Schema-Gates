// =====================================================================
//  and_using_nor.v
//  AND from three NORs (invert inputs, NOR).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module and_using_nor(input a, input b, output y);
    wire na, nb;
    assign na = ~(a | a);
    assign nb = ~(b | b);
    assign y  = ~(na | nb);
endmodule


