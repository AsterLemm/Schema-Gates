// =====================================================================
//  mux16_4.v
//  16:1 multiplexer, 4-bit data; tree of 2:1 muxes.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mux16_4(input [3:0] d0, input [3:0] d1, input [3:0] d2, input [3:0] d3, input [3:0] d4, input [3:0] d5, input [3:0] d6, input [3:0] d7, input [3:0] d8, input [3:0] d9, input [3:0] d10, input [3:0] d11, input [3:0] d12, input [3:0] d13, input [3:0] d14, input [3:0] d15, input [3:0] sel, output [3:0] y);
    // define sel input 200.120.255
    // define y output 120.255.160
    wire [3:0] w_s0_0;
    mux2_1 m_s0_0_b0(.d0(d0[0]), .d1(d1[0]), .sel(sel[0]), .y(w_s0_0[0]));
    mux2_1 m_s0_0_b1(.d0(d0[1]), .d1(d1[1]), .sel(sel[0]), .y(w_s0_0[1]));
    mux2_1 m_s0_0_b2(.d0(d0[2]), .d1(d1[2]), .sel(sel[0]), .y(w_s0_0[2]));
    mux2_1 m_s0_0_b3(.d0(d0[3]), .d1(d1[3]), .sel(sel[0]), .y(w_s0_0[3]));
    wire [3:0] w_s0_1;
    mux2_1 m_s0_1_b0(.d0(d2[0]), .d1(d3[0]), .sel(sel[0]), .y(w_s0_1[0]));
    mux2_1 m_s0_1_b1(.d0(d2[1]), .d1(d3[1]), .sel(sel[0]), .y(w_s0_1[1]));
    mux2_1 m_s0_1_b2(.d0(d2[2]), .d1(d3[2]), .sel(sel[0]), .y(w_s0_1[2]));
    mux2_1 m_s0_1_b3(.d0(d2[3]), .d1(d3[3]), .sel(sel[0]), .y(w_s0_1[3]));
    wire [3:0] w_s0_2;
    mux2_1 m_s0_2_b0(.d0(d4[0]), .d1(d5[0]), .sel(sel[0]), .y(w_s0_2[0]));
    mux2_1 m_s0_2_b1(.d0(d4[1]), .d1(d5[1]), .sel(sel[0]), .y(w_s0_2[1]));
    mux2_1 m_s0_2_b2(.d0(d4[2]), .d1(d5[2]), .sel(sel[0]), .y(w_s0_2[2]));
    mux2_1 m_s0_2_b3(.d0(d4[3]), .d1(d5[3]), .sel(sel[0]), .y(w_s0_2[3]));
    wire [3:0] w_s0_3;
    mux2_1 m_s0_3_b0(.d0(d6[0]), .d1(d7[0]), .sel(sel[0]), .y(w_s0_3[0]));
    mux2_1 m_s0_3_b1(.d0(d6[1]), .d1(d7[1]), .sel(sel[0]), .y(w_s0_3[1]));
    mux2_1 m_s0_3_b2(.d0(d6[2]), .d1(d7[2]), .sel(sel[0]), .y(w_s0_3[2]));
    mux2_1 m_s0_3_b3(.d0(d6[3]), .d1(d7[3]), .sel(sel[0]), .y(w_s0_3[3]));
    wire [3:0] w_s0_4;
    mux2_1 m_s0_4_b0(.d0(d8[0]), .d1(d9[0]), .sel(sel[0]), .y(w_s0_4[0]));
    mux2_1 m_s0_4_b1(.d0(d8[1]), .d1(d9[1]), .sel(sel[0]), .y(w_s0_4[1]));
    mux2_1 m_s0_4_b2(.d0(d8[2]), .d1(d9[2]), .sel(sel[0]), .y(w_s0_4[2]));
    mux2_1 m_s0_4_b3(.d0(d8[3]), .d1(d9[3]), .sel(sel[0]), .y(w_s0_4[3]));
    wire [3:0] w_s0_5;
    mux2_1 m_s0_5_b0(.d0(d10[0]), .d1(d11[0]), .sel(sel[0]), .y(w_s0_5[0]));
    mux2_1 m_s0_5_b1(.d0(d10[1]), .d1(d11[1]), .sel(sel[0]), .y(w_s0_5[1]));
    mux2_1 m_s0_5_b2(.d0(d10[2]), .d1(d11[2]), .sel(sel[0]), .y(w_s0_5[2]));
    mux2_1 m_s0_5_b3(.d0(d10[3]), .d1(d11[3]), .sel(sel[0]), .y(w_s0_5[3]));
    wire [3:0] w_s0_6;
    mux2_1 m_s0_6_b0(.d0(d12[0]), .d1(d13[0]), .sel(sel[0]), .y(w_s0_6[0]));
    mux2_1 m_s0_6_b1(.d0(d12[1]), .d1(d13[1]), .sel(sel[0]), .y(w_s0_6[1]));
    mux2_1 m_s0_6_b2(.d0(d12[2]), .d1(d13[2]), .sel(sel[0]), .y(w_s0_6[2]));
    mux2_1 m_s0_6_b3(.d0(d12[3]), .d1(d13[3]), .sel(sel[0]), .y(w_s0_6[3]));
    wire [3:0] w_s0_7;
    mux2_1 m_s0_7_b0(.d0(d14[0]), .d1(d15[0]), .sel(sel[0]), .y(w_s0_7[0]));
    mux2_1 m_s0_7_b1(.d0(d14[1]), .d1(d15[1]), .sel(sel[0]), .y(w_s0_7[1]));
    mux2_1 m_s0_7_b2(.d0(d14[2]), .d1(d15[2]), .sel(sel[0]), .y(w_s0_7[2]));
    mux2_1 m_s0_7_b3(.d0(d14[3]), .d1(d15[3]), .sel(sel[0]), .y(w_s0_7[3]));
    wire [3:0] w_s1_0;
    mux2_1 m_s1_0_b0(.d0(w_s0_0[0]), .d1(w_s0_1[0]), .sel(sel[1]), .y(w_s1_0[0]));
    mux2_1 m_s1_0_b1(.d0(w_s0_0[1]), .d1(w_s0_1[1]), .sel(sel[1]), .y(w_s1_0[1]));
    mux2_1 m_s1_0_b2(.d0(w_s0_0[2]), .d1(w_s0_1[2]), .sel(sel[1]), .y(w_s1_0[2]));
    mux2_1 m_s1_0_b3(.d0(w_s0_0[3]), .d1(w_s0_1[3]), .sel(sel[1]), .y(w_s1_0[3]));
    wire [3:0] w_s1_1;
    mux2_1 m_s1_1_b0(.d0(w_s0_2[0]), .d1(w_s0_3[0]), .sel(sel[1]), .y(w_s1_1[0]));
    mux2_1 m_s1_1_b1(.d0(w_s0_2[1]), .d1(w_s0_3[1]), .sel(sel[1]), .y(w_s1_1[1]));
    mux2_1 m_s1_1_b2(.d0(w_s0_2[2]), .d1(w_s0_3[2]), .sel(sel[1]), .y(w_s1_1[2]));
    mux2_1 m_s1_1_b3(.d0(w_s0_2[3]), .d1(w_s0_3[3]), .sel(sel[1]), .y(w_s1_1[3]));
    wire [3:0] w_s1_2;
    mux2_1 m_s1_2_b0(.d0(w_s0_4[0]), .d1(w_s0_5[0]), .sel(sel[1]), .y(w_s1_2[0]));
    mux2_1 m_s1_2_b1(.d0(w_s0_4[1]), .d1(w_s0_5[1]), .sel(sel[1]), .y(w_s1_2[1]));
    mux2_1 m_s1_2_b2(.d0(w_s0_4[2]), .d1(w_s0_5[2]), .sel(sel[1]), .y(w_s1_2[2]));
    mux2_1 m_s1_2_b3(.d0(w_s0_4[3]), .d1(w_s0_5[3]), .sel(sel[1]), .y(w_s1_2[3]));
    wire [3:0] w_s1_3;
    mux2_1 m_s1_3_b0(.d0(w_s0_6[0]), .d1(w_s0_7[0]), .sel(sel[1]), .y(w_s1_3[0]));
    mux2_1 m_s1_3_b1(.d0(w_s0_6[1]), .d1(w_s0_7[1]), .sel(sel[1]), .y(w_s1_3[1]));
    mux2_1 m_s1_3_b2(.d0(w_s0_6[2]), .d1(w_s0_7[2]), .sel(sel[1]), .y(w_s1_3[2]));
    mux2_1 m_s1_3_b3(.d0(w_s0_6[3]), .d1(w_s0_7[3]), .sel(sel[1]), .y(w_s1_3[3]));
    wire [3:0] w_s2_0;
    mux2_1 m_s2_0_b0(.d0(w_s1_0[0]), .d1(w_s1_1[0]), .sel(sel[2]), .y(w_s2_0[0]));
    mux2_1 m_s2_0_b1(.d0(w_s1_0[1]), .d1(w_s1_1[1]), .sel(sel[2]), .y(w_s2_0[1]));
    mux2_1 m_s2_0_b2(.d0(w_s1_0[2]), .d1(w_s1_1[2]), .sel(sel[2]), .y(w_s2_0[2]));
    mux2_1 m_s2_0_b3(.d0(w_s1_0[3]), .d1(w_s1_1[3]), .sel(sel[2]), .y(w_s2_0[3]));
    wire [3:0] w_s2_1;
    mux2_1 m_s2_1_b0(.d0(w_s1_2[0]), .d1(w_s1_3[0]), .sel(sel[2]), .y(w_s2_1[0]));
    mux2_1 m_s2_1_b1(.d0(w_s1_2[1]), .d1(w_s1_3[1]), .sel(sel[2]), .y(w_s2_1[1]));
    mux2_1 m_s2_1_b2(.d0(w_s1_2[2]), .d1(w_s1_3[2]), .sel(sel[2]), .y(w_s2_1[2]));
    mux2_1 m_s2_1_b3(.d0(w_s1_2[3]), .d1(w_s1_3[3]), .sel(sel[2]), .y(w_s2_1[3]));
    wire [3:0] w_s3_0;
    mux2_1 m_s3_0_b0(.d0(w_s2_0[0]), .d1(w_s2_1[0]), .sel(sel[3]), .y(w_s3_0[0]));
    mux2_1 m_s3_0_b1(.d0(w_s2_0[1]), .d1(w_s2_1[1]), .sel(sel[3]), .y(w_s3_0[1]));
    mux2_1 m_s3_0_b2(.d0(w_s2_0[2]), .d1(w_s2_1[2]), .sel(sel[3]), .y(w_s3_0[2]));
    mux2_1 m_s3_0_b3(.d0(w_s2_0[3]), .d1(w_s2_1[3]), .sel(sel[3]), .y(w_s3_0[3]));
    assign y = w_s3_0;
endmodule

module mux2_1(input d0, input d1, input sel, output y);
    assign y = sel ? d1 : d0;
endmodule


