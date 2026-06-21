// =====================================================================
//  mux2_1.v
//  2:1 multiplexer, 1-bit data; tree of 2:1 muxes.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mux2_1(input d0, input d1, input sel, output y);
    // define sel input 200.120.255
    // define y output 120.255.160
    assign y = sel ? d1 : d0;
endmodule


