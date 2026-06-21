// =====================================================================
//  sr_latch_nor.v
//  SR latch (cross-coupled NOR).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sr_latch_nor(input s, input r, output q, output qn);
    // define s input 80.160.255
    // define r input 255.80.80
    // define q output 120.255.160
    assign q  = ~(r | qn);
    assign qn = ~(s | q);
endmodule


