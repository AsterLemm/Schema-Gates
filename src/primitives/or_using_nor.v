// =====================================================================
//  or_using_nor.v
//  OR from two NORs (NOR then invert).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module or_using_nor(input a, input b, output y);
    wire t;
    assign t = ~(a | b);
    assign y = ~(t | t);
endmodule


