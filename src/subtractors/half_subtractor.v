// =====================================================================
//  half_subtractor.v
//  Half subtractor: diff=a^b, bout=~a&b.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module half_subtractor(input a, input b, output diff, output bout);
    assign diff = a ^ b;
    assign bout = (~a) & b;
endmodule


