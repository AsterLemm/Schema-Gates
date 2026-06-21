// =====================================================================
//  carry_propagate_cell.v
//  Carry propagate p=a^b.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module carry_propagate_cell(input a, input b, output p);
    assign p = a ^ b;
endmodule


