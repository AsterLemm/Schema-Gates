// =====================================================================
//  nor_reduce16.v
//  NOR-reduce: 1 iff all bits zero.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module nor_reduce16(input [15:0] a, output y);
    assign y = ~(|a);
endmodule


