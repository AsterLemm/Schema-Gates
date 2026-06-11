// =====================================================================
//  edge_detector_both.v
//  Any-edge detector.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module edge_detector_both(input clk, input a, output edge_any);
    reg p;
    always @(posedge clk) p<=a;
    assign edge_any = a ^ p;
endmodule


