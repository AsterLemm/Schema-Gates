// =====================================================================
//  d_latch.v
//  D latch (transparent when en=1).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module d_latch(input d, input en, output reg q);
    // define d input 80.160.255   // define en input 255.180.80   // define q output 120.255.160
    always @(*) if (en) q = d;
endmodule


