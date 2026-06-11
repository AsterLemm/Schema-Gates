// =====================================================================
//  edge_detector_falling.v
//  Falling-edge detector.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module edge_detector_falling(input clk, input a, output fall);
    reg p;
    always @(posedge clk) p<=a;
    assign fall = ~a & p;
endmodule


