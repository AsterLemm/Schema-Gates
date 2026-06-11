// =====================================================================
//  gray_cell.v
//  Prefix 'gray' cell (carry-only merge).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gray_cell(input gk, input pk, input gj, output g);
    assign g = gk | (pk & gj);
endmodule


