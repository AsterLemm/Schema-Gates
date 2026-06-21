// =====================================================================
//  sr_latch_nand.v
//  SR latch (cross-coupled NAND, active-low).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sr_latch_nand(input s, input r, output q, output qn);
    // define s input 80.160.255
    // define r input 255.80.80
    // define q output 120.255.160
    assign q  = ~(s & qn);
    assign qn = ~(r & q);
endmodule


