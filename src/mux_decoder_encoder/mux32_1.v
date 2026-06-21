// =====================================================================
//  mux32_1.v
//  32:1 multiplexer, 1-bit data; tree of 2:1 muxes.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mux32_1(input d0, input d1, input d2, input d3, input d4, input d5, input d6, input d7, input d8, input d9, input d10, input d11, input d12, input d13, input d14, input d15, input d16, input d17, input d18, input d19, input d20, input d21, input d22, input d23, input d24, input d25, input d26, input d27, input d28, input d29, input d30, input d31, input [4:0] sel, output y);
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
    wire w_s0_8;
    mux2_1 m_s0_8(.d0(d16), .d1(d17), .sel(sel[0]), .y(w_s0_8));
    wire w_s0_9;
    mux2_1 m_s0_9(.d0(d18), .d1(d19), .sel(sel[0]), .y(w_s0_9));
    wire w_s0_10;
    mux2_1 m_s0_10(.d0(d20), .d1(d21), .sel(sel[0]), .y(w_s0_10));
    wire w_s0_11;
    mux2_1 m_s0_11(.d0(d22), .d1(d23), .sel(sel[0]), .y(w_s0_11));
    wire w_s0_12;
    mux2_1 m_s0_12(.d0(d24), .d1(d25), .sel(sel[0]), .y(w_s0_12));
    wire w_s0_13;
    mux2_1 m_s0_13(.d0(d26), .d1(d27), .sel(sel[0]), .y(w_s0_13));
    wire w_s0_14;
    mux2_1 m_s0_14(.d0(d28), .d1(d29), .sel(sel[0]), .y(w_s0_14));
    wire w_s0_15;
    mux2_1 m_s0_15(.d0(d30), .d1(d31), .sel(sel[0]), .y(w_s0_15));
    wire w_s1_0;
    mux2_1 m_s1_0(.d0(w_s0_0), .d1(w_s0_1), .sel(sel[1]), .y(w_s1_0));
    wire w_s1_1;
    mux2_1 m_s1_1(.d0(w_s0_2), .d1(w_s0_3), .sel(sel[1]), .y(w_s1_1));
    wire w_s1_2;
    mux2_1 m_s1_2(.d0(w_s0_4), .d1(w_s0_5), .sel(sel[1]), .y(w_s1_2));
    wire w_s1_3;
    mux2_1 m_s1_3(.d0(w_s0_6), .d1(w_s0_7), .sel(sel[1]), .y(w_s1_3));
    wire w_s1_4;
    mux2_1 m_s1_4(.d0(w_s0_8), .d1(w_s0_9), .sel(sel[1]), .y(w_s1_4));
    wire w_s1_5;
    mux2_1 m_s1_5(.d0(w_s0_10), .d1(w_s0_11), .sel(sel[1]), .y(w_s1_5));
    wire w_s1_6;
    mux2_1 m_s1_6(.d0(w_s0_12), .d1(w_s0_13), .sel(sel[1]), .y(w_s1_6));
    wire w_s1_7;
    mux2_1 m_s1_7(.d0(w_s0_14), .d1(w_s0_15), .sel(sel[1]), .y(w_s1_7));
    wire w_s2_0;
    mux2_1 m_s2_0(.d0(w_s1_0), .d1(w_s1_1), .sel(sel[2]), .y(w_s2_0));
    wire w_s2_1;
    mux2_1 m_s2_1(.d0(w_s1_2), .d1(w_s1_3), .sel(sel[2]), .y(w_s2_1));
    wire w_s2_2;
    mux2_1 m_s2_2(.d0(w_s1_4), .d1(w_s1_5), .sel(sel[2]), .y(w_s2_2));
    wire w_s2_3;
    mux2_1 m_s2_3(.d0(w_s1_6), .d1(w_s1_7), .sel(sel[2]), .y(w_s2_3));
    wire w_s3_0;
    mux2_1 m_s3_0(.d0(w_s2_0), .d1(w_s2_1), .sel(sel[3]), .y(w_s3_0));
    wire w_s3_1;
    mux2_1 m_s3_1(.d0(w_s2_2), .d1(w_s2_3), .sel(sel[3]), .y(w_s3_1));
    wire w_s4_0;
    mux2_1 m_s4_0(.d0(w_s3_0), .d1(w_s3_1), .sel(sel[4]), .y(w_s4_0));
    assign y = w_s4_0;
endmodule

module mux2_1(input d0, input d1, input sel, output y);
    assign y = sel ? d1 : d0;
endmodule


