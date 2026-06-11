// =====================================================================
//  mux2_8.v
//  2:1 multiplexer, 8-bit data; tree of 2:1 muxes.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mux2_8(input [7:0] d0, input [7:0] d1, input [0:0] sel, output [7:0] y);
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
    assign y = w_s0_0;
endmodule

module mux2_1(input d0, input d1, input sel, output y);
    assign y = sel ? d1 : d0;
endmodule


