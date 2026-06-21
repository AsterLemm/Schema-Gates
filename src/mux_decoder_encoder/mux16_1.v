// =====================================================================
//  mux16_1.v
//  16:1 multiplexer, 1-bit data; tree of 2:1 muxes.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mux16_1(input d0, input d1, input d2, input d3, input d4, input d5, input d6, input d7, input d8, input d9, input d10, input d11, input d12, input d13, input d14, input d15, input [3:0] sel, output y);
    // define sel input 200.120.255
    // define y output 120.255.160
    wire w_s0_0;
    mux2_1 m_s0_0(.d0(d0), .d1(d1), .sel(sel[0]), .y(w_s0_0));
    wire w_s0_1;
    mux2_1 m_s0_1(.d0(d2), .d1(d3), .sel(sel[0]), .y(w_s0_1));
    wire w_s0_2;
    mux2_1 m_s0_2(.d0(d4), .d1(d5), .sel(sel[0]), .y(w_s0_2));
    wire w_s0_3;
    mux2_1 m_s0_3(.d0(d6), .d1(d7), .sel(sel[0]), .y(w_s0_3));
    wire w_s0_4;
    mux2_1 m_s0_4(.d0(d8), .d1(d9), .sel(sel[0]), .y(w_s0_4));
    wire w_s0_5;
    mux2_1 m_s0_5(.d0(d10), .d1(d11), .sel(sel[0]), .y(w_s0_5));
    wire w_s0_6;
    mux2_1 m_s0_6(.d0(d12), .d1(d13), .sel(sel[0]), .y(w_s0_6));
    wire w_s0_7;
    mux2_1 m_s0_7(.d0(d14), .d1(d15), .sel(sel[0]), .y(w_s0_7));
    wire w_s1_0;
    mux2_1 m_s1_0(.d0(w_s0_0), .d1(w_s0_1), .sel(sel[1]), .y(w_s1_0));
    wire w_s1_1;
    mux2_1 m_s1_1(.d0(w_s0_2), .d1(w_s0_3), .sel(sel[1]), .y(w_s1_1));
    wire w_s1_2;
    mux2_1 m_s1_2(.d0(w_s0_4), .d1(w_s0_5), .sel(sel[1]), .y(w_s1_2));
    wire w_s1_3;
    mux2_1 m_s1_3(.d0(w_s0_6), .d1(w_s0_7), .sel(sel[1]), .y(w_s1_3));
    wire w_s2_0;
    mux2_1 m_s2_0(.d0(w_s1_0), .d1(w_s1_1), .sel(sel[2]), .y(w_s2_0));
    wire w_s2_1;
    mux2_1 m_s2_1(.d0(w_s1_2), .d1(w_s1_3), .sel(sel[2]), .y(w_s2_1));
    wire w_s3_0;
    mux2_1 m_s3_0(.d0(w_s2_0), .d1(w_s2_1), .sel(sel[3]), .y(w_s3_0));
    assign y = w_s3_0;
endmodule

module mux2_1(input d0, input d1, input sel, output y);
    assign y = sel ? d1 : d0;
endmodule


