// =====================================================================
//  borrow_propagate_cell.v
//  Borrow propagate bp = ~(a^b).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module borrow_propagate_cell(input a, input b, output bp);
    assign bp = ~(a ^ b);
endmodule


