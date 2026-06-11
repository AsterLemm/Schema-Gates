// =====================================================================
//  edge_detector_rising.v
//  Rising-edge detector.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module edge_detector_rising(input clk, input a, output rise);
    reg p;
    always @(posedge clk) p<=a;
    assign rise = a & ~p;
endmodule


