// =====================================================================
//  full_adder_pg.v
//  Full adder exposing propagate/generate.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module full_adder_pg(input a, input b, input cin, output sum, output cout, output p, output g);
    assign p = a ^ b;
    assign g = a & b;
    assign sum = p ^ cin;
    assign cout = g | (p & cin);
endmodule


