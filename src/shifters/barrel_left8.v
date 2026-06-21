// =====================================================================
//  barrel_left8.v
//  8-bit barrel left shifter (log2 mux stages).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module barrel_left8(input [7:0] a, input [2:0] sh, output [7:0] y);
    // define a input 80.160.255
    // define sh input 200.120.255
    // define y output 120.255.160
    wire [7:0] st0;
    mux2_1 m0_0(.d0(a[0]), .d1(1'b0), .sel(sh[0]), .y(st0[0]));
    mux2_1 m0_1(.d0(a[1]), .d1(a[0]), .sel(sh[0]), .y(st0[1]));
    mux2_1 m0_2(.d0(a[2]), .d1(a[1]), .sel(sh[0]), .y(st0[2]));
    mux2_1 m0_3(.d0(a[3]), .d1(a[2]), .sel(sh[0]), .y(st0[3]));
    mux2_1 m0_4(.d0(a[4]), .d1(a[3]), .sel(sh[0]), .y(st0[4]));
    mux2_1 m0_5(.d0(a[5]), .d1(a[4]), .sel(sh[0]), .y(st0[5]));
    mux2_1 m0_6(.d0(a[6]), .d1(a[5]), .sel(sh[0]), .y(st0[6]));
    mux2_1 m0_7(.d0(a[7]), .d1(a[6]), .sel(sh[0]), .y(st0[7]));
    wire [7:0] st1;
    mux2_1 m1_0(.d0(st0[0]), .d1(1'b0), .sel(sh[1]), .y(st1[0]));
    mux2_1 m1_1(.d0(st0[1]), .d1(1'b0), .sel(sh[1]), .y(st1[1]));
    mux2_1 m1_2(.d0(st0[2]), .d1(st0[0]), .sel(sh[1]), .y(st1[2]));
    mux2_1 m1_3(.d0(st0[3]), .d1(st0[1]), .sel(sh[1]), .y(st1[3]));
    mux2_1 m1_4(.d0(st0[4]), .d1(st0[2]), .sel(sh[1]), .y(st1[4]));
    mux2_1 m1_5(.d0(st0[5]), .d1(st0[3]), .sel(sh[1]), .y(st1[5]));
    mux2_1 m1_6(.d0(st0[6]), .d1(st0[4]), .sel(sh[1]), .y(st1[6]));
    mux2_1 m1_7(.d0(st0[7]), .d1(st0[5]), .sel(sh[1]), .y(st1[7]));
    wire [7:0] st2;
    mux2_1 m2_0(.d0(st1[0]), .d1(1'b0), .sel(sh[2]), .y(st2[0]));
    mux2_1 m2_1(.d0(st1[1]), .d1(1'b0), .sel(sh[2]), .y(st2[1]));
    mux2_1 m2_2(.d0(st1[2]), .d1(1'b0), .sel(sh[2]), .y(st2[2]));
    mux2_1 m2_3(.d0(st1[3]), .d1(1'b0), .sel(sh[2]), .y(st2[3]));
    mux2_1 m2_4(.d0(st1[4]), .d1(st1[0]), .sel(sh[2]), .y(st2[4]));
    mux2_1 m2_5(.d0(st1[5]), .d1(st1[1]), .sel(sh[2]), .y(st2[5]));
    mux2_1 m2_6(.d0(st1[6]), .d1(st1[2]), .sel(sh[2]), .y(st2[6]));
    mux2_1 m2_7(.d0(st1[7]), .d1(st1[3]), .sel(sh[2]), .y(st2[7]));
    assign y = st2;
endmodule

module mux2_1(input d0, input d1, input sel, output y);
    assign y = sel ? d1 : d0;
endmodule


