// =====================================================================
//  or8.v
//  Basic gate: y = a | b | c | d | e | f | g | h
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module or8(input a, input b, input c, input d, input e, input f, input g, input h, output y);
    assign y = a | b | c | d | e | f | g | h;
endmodule


