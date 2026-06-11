// =====================================================================
//  mux4_1.v
//  4:1 multiplexer, 1-bit data; tree of 2:1 muxes.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mux4_1(input d0, input d1, input d2, input d3, input [1:0] sel, output y);
    // define sel input 200.120.255    // define y output 120.255.160
    wire w_s0_0;
    mux2_1 m_s0_0(.d0(d0), .d1(d1), .sel(sel[0]), .y(w_s0_0));
    wire w_s0_1;
    mux2_1 m_s0_1(.d0(d2), .d1(d3), .sel(sel[0]), .y(w_s0_1));
    wire w_s1_0;
    mux2_1 m_s1_0(.d0(w_s0_0), .d1(w_s0_1), .sel(sel[1]), .y(w_s1_0));
    assign y = w_s1_0;
endmodule

module mux2_1(input d0, input d1, input sel, output y);
    assign y = sel ? d1 : d0;
endmodule


