// =====================================================================
//  compressor5to3.v
//  5:3 counter (popcount of 5 bits).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module compressor5to3(input a, input b, input c, input d, input e, output [2:0] sum);
    // counts number of 1s among 5 inputs (0..5) -> 3-bit
    assign sum = a + b + c + d + e;
endmodule


