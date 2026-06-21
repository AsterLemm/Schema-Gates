// =====================================================================
//  barrel_left4.v
//  4-bit barrel left shifter (log2 mux stages).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module barrel_left4(input [3:0] a, input [1:0] sh, output [3:0] y);
    // define a input 80.160.255
    // define sh input 200.120.255
    // define y output 120.255.160
    wire [3:0] st0;
    mux2_1 m0_0(.d0(a[0]), .d1(1'b0), .sel(sh[0]), .y(st0[0]));
    mux2_1 m0_1(.d0(a[1]), .d1(a[0]), .sel(sh[0]), .y(st0[1]));
    mux2_1 m0_2(.d0(a[2]), .d1(a[1]), .sel(sh[0]), .y(st0[2]));
    mux2_1 m0_3(.d0(a[3]), .d1(a[2]), .sel(sh[0]), .y(st0[3]));
    wire [3:0] st1;
    mux2_1 m1_0(.d0(st0[0]), .d1(1'b0), .sel(sh[1]), .y(st1[0]));
    mux2_1 m1_1(.d0(st0[1]), .d1(1'b0), .sel(sh[1]), .y(st1[1]));
    mux2_1 m1_2(.d0(st0[2]), .d1(st0[0]), .sel(sh[1]), .y(st1[2]));
    mux2_1 m1_3(.d0(st0[3]), .d1(st0[1]), .sel(sh[1]), .y(st1[3]));
    assign y = st1;
endmodule

module mux2_1(input d0, input d1, input sel, output y);
    assign y = sel ? d1 : d0;
endmodule


