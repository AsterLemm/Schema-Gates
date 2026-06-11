// =====================================================================
//  bit_tap.v
//  Probe/tap a single bit (pass-through).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bit_tap(input a, output y);
    assign y = a;
endmodule


