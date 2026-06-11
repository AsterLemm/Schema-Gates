// =====================================================================
//  full_subtractor.v
//  Full subtractor: diff=a^b^bin, borrow out.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module full_subtractor(input a, input b, input bin, output diff, output bout);
    wire d0, b0, b1;
    assign d0   = a ^ b;
    assign diff = d0 ^ bin;
    assign b0   = (~a) & b;
    assign b1   = (~d0) & bin;
    assign bout = b0 | b1;
endmodule


