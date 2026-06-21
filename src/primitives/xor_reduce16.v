// =====================================================================
//  xor_reduce16.v
//  XOR-reduce: parity of the bus.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module xor_reduce16(input [15:0] a, output y);
    assign y = ^a;
endmodule


