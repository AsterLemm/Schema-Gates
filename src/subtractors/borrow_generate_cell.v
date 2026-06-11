// =====================================================================
//  borrow_generate_cell.v
//  Borrow generate bg = ~a & b.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module borrow_generate_cell(input a, input b, output bg);
    assign bg = (~a) & b;
endmodule


