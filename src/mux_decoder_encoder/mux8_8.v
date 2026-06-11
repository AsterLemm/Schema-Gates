// =====================================================================
//  mux8_8.v
//  8:1 multiplexer, 8-bit data; tree of 2:1 muxes.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mux8_8(input [7:0] d0, input [7:0] d1, input [7:0] d2, input [7:0] d3, input [7:0] d4, input [7:0] d5, input [7:0] d6, input [7:0] d7, input [2:0] sel, output [7:0] y);
    // define sel input 200.120.255    // define y output 120.255.160
    wire [7:0] w_s0_0;
    mux2_1 m_s0_0_b0(.d0(d0[0]), .d1(d1[0]), .sel(sel[0]), .y(w_s0_0[0]));
    mux2_1 m_s0_0_b1(.d0(d0[1]), .d1(d1[1]), .sel(sel[0]), .y(w_s0_0[1]));
    mux2_1 m_s0_0_b2(.d0(d0[2]), .d1(d1[2]), .sel(sel[0]), .y(w_s0_0[2]));
    mux2_1 m_s0_0_b3(.d0(d0[3]), .d1(d1[3]), .sel(sel[0]), .y(w_s0_0[3]));
    mux2_1 m_s0_0_b4(.d0(d0[4]), .d1(d1[4]), .sel(sel[0]), .y(w_s0_0[4]));
    mux2_1 m_s0_0_b5(.d0(d0[5]), .d1(d1[5]), .sel(sel[0]), .y(w_s0_0[5]));
    mux2_1 m_s0_0_b6(.d0(d0[6]), .d1(d1[6]), .sel(sel[0]), .y(w_s0_0[6]));
    mux2_1 m_s0_0_b7(.d0(d0[7]), .d1(d1[7]), .sel(sel[0]), .y(w_s0_0[7]));
    wire [7:0] w_s0_1;
    mux2_1 m_s0_1_b0(.d0(d2[0]), .d1(d3[0]), .sel(sel[0]), .y(w_s0_1[0]));
    mux2_1 m_s0_1_b1(.d0(d2[1]), .d1(d3[1]), .sel(sel[0]), .y(w_s0_1[1]));
    mux2_1 m_s0_1_b2(.d0(d2[2]), .d1(d3[2]), .sel(sel[0]), .y(w_s0_1[2]));
    mux2_1 m_s0_1_b3(.d0(d2[3]), .d1(d3[3]), .sel(sel[0]), .y(w_s0_1[3]));
    mux2_1 m_s0_1_b4(.d0(d2[4]), .d1(d3[4]), .sel(sel[0]), .y(w_s0_1[4]));
    mux2_1 m_s0_1_b5(.d0(d2[5]), .d1(d3[5]), .sel(sel[0]), .y(w_s0_1[5]));
    mux2_1 m_s0_1_b6(.d0(d2[6]), .d1(d3[6]), .sel(sel[0]), .y(w_s0_1[6]));
    mux2_1 m_s0_1_b7(.d0(d2[7]), .d1(d3[7]), .sel(sel[0]), .y(w_s0_1[7]));
    wire [7:0] w_s0_2;
    mux2_1 m_s0_2_b0(.d0(d4[0]), .d1(d5[0]), .sel(sel[0]), .y(w_s0_2[0]));
    mux2_1 m_s0_2_b1(.d0(d4[1]), .d1(d5[1]), .sel(sel[0]), .y(w_s0_2[1]));
    mux2_1 m_s0_2_b2(.d0(d4[2]), .d1(d5[2]), .sel(sel[0]), .y(w_s0_2[2]));
    mux2_1 m_s0_2_b3(.d0(d4[3]), .d1(d5[3]), .sel(sel[0]), .y(w_s0_2[3]));
    mux2_1 m_s0_2_b4(.d0(d4[4]), .d1(d5[4]), .sel(sel[0]), .y(w_s0_2[4]));
    mux2_1 m_s0_2_b5(.d0(d4[5]), .d1(d5[5]), .sel(sel[0]), .y(w_s0_2[5]));
    mux2_1 m_s0_2_b6(.d0(d4[6]), .d1(d5[6]), .sel(sel[0]), .y(w_s0_2[6]));
    mux2_1 m_s0_2_b7(.d0(d4[7]), .d1(d5[7]), .sel(sel[0]), .y(w_s0_2[7]));
    wire [7:0] w_s0_3;
    mux2_1 m_s0_3_b0(.d0(d6[0]), .d1(d7[0]), .sel(sel[0]), .y(w_s0_3[0]));
    mux2_1 m_s0_3_b1(.d0(d6[1]), .d1(d7[1]), .sel(sel[0]), .y(w_s0_3[1]));
    mux2_1 m_s0_3_b2(.d0(d6[2]), .d1(d7[2]), .sel(sel[0]), .y(w_s0_3[2]));
    mux2_1 m_s0_3_b3(.d0(d6[3]), .d1(d7[3]), .sel(sel[0]), .y(w_s0_3[3]));
    mux2_1 m_s0_3_b4(.d0(d6[4]), .d1(d7[4]), .sel(sel[0]), .y(w_s0_3[4]));
    mux2_1 m_s0_3_b5(.d0(d6[5]), .d1(d7[5]), .sel(sel[0]), .y(w_s0_3[5]));
    mux2_1 m_s0_3_b6(.d0(d6[6]), .d1(d7[6]), .sel(sel[0]), .y(w_s0_3[6]));
    mux2_1 m_s0_3_b7(.d0(d6[7]), .d1(d7[7]), .sel(sel[0]), .y(w_s0_3[7]));
    wire [7:0] w_s1_0;
    mux2_1 m_s1_0_b0(.d0(w_s0_0[0]), .d1(w_s0_1[0]), .sel(sel[1]), .y(w_s1_0[0]));
    mux2_1 m_s1_0_b1(.d0(w_s0_0[1]), .d1(w_s0_1[1]), .sel(sel[1]), .y(w_s1_0[1]));
    mux2_1 m_s1_0_b2(.d0(w_s0_0[2]), .d1(w_s0_1[2]), .sel(sel[1]), .y(w_s1_0[2]));
    mux2_1 m_s1_0_b3(.d0(w_s0_0[3]), .d1(w_s0_1[3]), .sel(sel[1]), .y(w_s1_0[3]));
    mux2_1 m_s1_0_b4(.d0(w_s0_0[4]), .d1(w_s0_1[4]), .sel(sel[1]), .y(w_s1_0[4]));
    mux2_1 m_s1_0_b5(.d0(w_s0_0[5]), .d1(w_s0_1[5]), .sel(sel[1]), .y(w_s1_0[5]));
    mux2_1 m_s1_0_b6(.d0(w_s0_0[6]), .d1(w_s0_1[6]), .sel(sel[1]), .y(w_s1_0[6]));
    mux2_1 m_s1_0_b7(.d0(w_s0_0[7]), .d1(w_s0_1[7]), .sel(sel[1]), .y(w_s1_0[7]));
    wire [7:0] w_s1_1;
    mux2_1 m_s1_1_b0(.d0(w_s0_2[0]), .d1(w_s0_3[0]), .sel(sel[1]), .y(w_s1_1[0]));
    mux2_1 m_s1_1_b1(.d0(w_s0_2[1]), .d1(w_s0_3[1]), .sel(sel[1]), .y(w_s1_1[1]));
    mux2_1 m_s1_1_b2(.d0(w_s0_2[2]), .d1(w_s0_3[2]), .sel(sel[1]), .y(w_s1_1[2]));
    mux2_1 m_s1_1_b3(.d0(w_s0_2[3]), .d1(w_s0_3[3]), .sel(sel[1]), .y(w_s1_1[3]));
    mux2_1 m_s1_1_b4(.d0(w_s0_2[4]), .d1(w_s0_3[4]), .sel(sel[1]), .y(w_s1_1[4]));
    mux2_1 m_s1_1_b5(.d0(w_s0_2[5]), .d1(w_s0_3[5]), .sel(sel[1]), .y(w_s1_1[5]));
    mux2_1 m_s1_1_b6(.d0(w_s0_2[6]), .d1(w_s0_3[6]), .sel(sel[1]), .y(w_s1_1[6]));
    mux2_1 m_s1_1_b7(.d0(w_s0_2[7]), .d1(w_s0_3[7]), .sel(sel[1]), .y(w_s1_1[7]));
    wire [7:0] w_s2_0;
    mux2_1 m_s2_0_b0(.d0(w_s1_0[0]), .d1(w_s1_1[0]), .sel(sel[2]), .y(w_s2_0[0]));
    mux2_1 m_s2_0_b1(.d0(w_s1_0[1]), .d1(w_s1_1[1]), .sel(sel[2]), .y(w_s2_0[1]));
    mux2_1 m_s2_0_b2(.d0(w_s1_0[2]), .d1(w_s1_1[2]), .sel(sel[2]), .y(w_s2_0[2]));
    mux2_1 m_s2_0_b3(.d0(w_s1_0[3]), .d1(w_s1_1[3]), .sel(sel[2]), .y(w_s2_0[3]));
    mux2_1 m_s2_0_b4(.d0(w_s1_0[4]), .d1(w_s1_1[4]), .sel(sel[2]), .y(w_s2_0[4]));
    mux2_1 m_s2_0_b5(.d0(w_s1_0[5]), .d1(w_s1_1[5]), .sel(sel[2]), .y(w_s2_0[5]));
    mux2_1 m_s2_0_b6(.d0(w_s1_0[6]), .d1(w_s1_1[6]), .sel(sel[2]), .y(w_s2_0[6]));
    mux2_1 m_s2_0_b7(.d0(w_s1_0[7]), .d1(w_s1_1[7]), .sel(sel[2]), .y(w_s2_0[7]));
    assign y = w_s2_0;
endmodule

module mux2_1(input d0, input d1, input sel, output y);
    assign y = sel ? d1 : d0;
endmodule


