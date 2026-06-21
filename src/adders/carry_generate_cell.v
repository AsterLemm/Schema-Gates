// =====================================================================
//  carry_generate_cell.v
//  Carry generate g=a&b.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module carry_generate_cell(input a, input b, output g);
    assign g = a & b;
endmodule


