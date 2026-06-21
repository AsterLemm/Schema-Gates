// =====================================================================
//  barrel_left16.v
//  16-bit barrel left shifter (log2 mux stages).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module barrel_left16(input [15:0] a, input [3:0] sh, output [15:0] y);
    // define a input 80.160.255
    // define sh input 200.120.255
    // define y output 120.255.160
    wire [15:0] st0;
    mux2_1 m0_0(.d0(a[0]), .d1(1'b0), .sel(sh[0]), .y(st0[0]));
    mux2_1 m0_1(.d0(a[1]), .d1(a[0]), .sel(sh[0]), .y(st0[1]));
    mux2_1 m0_2(.d0(a[2]), .d1(a[1]), .sel(sh[0]), .y(st0[2]));
    mux2_1 m0_3(.d0(a[3]), .d1(a[2]), .sel(sh[0]), .y(st0[3]));
    mux2_1 m0_4(.d0(a[4]), .d1(a[3]), .sel(sh[0]), .y(st0[4]));
    mux2_1 m0_5(.d0(a[5]), .d1(a[4]), .sel(sh[0]), .y(st0[5]));
    mux2_1 m0_6(.d0(a[6]), .d1(a[5]), .sel(sh[0]), .y(st0[6]));
    mux2_1 m0_7(.d0(a[7]), .d1(a[6]), .sel(sh[0]), .y(st0[7]));
    mux2_1 m0_8(.d0(a[8]), .d1(a[7]), .sel(sh[0]), .y(st0[8]));
    mux2_1 m0_9(.d0(a[9]), .d1(a[8]), .sel(sh[0]), .y(st0[9]));
    mux2_1 m0_10(.d0(a[10]), .d1(a[9]), .sel(sh[0]), .y(st0[10]));
    mux2_1 m0_11(.d0(a[11]), .d1(a[10]), .sel(sh[0]), .y(st0[11]));
    mux2_1 m0_12(.d0(a[12]), .d1(a[11]), .sel(sh[0]), .y(st0[12]));
    mux2_1 m0_13(.d0(a[13]), .d1(a[12]), .sel(sh[0]), .y(st0[13]));
    mux2_1 m0_14(.d0(a[14]), .d1(a[13]), .sel(sh[0]), .y(st0[14]));
    mux2_1 m0_15(.d0(a[15]), .d1(a[14]), .sel(sh[0]), .y(st0[15]));
    wire [15:0] st1;
    mux2_1 m1_0(.d0(st0[0]), .d1(1'b0), .sel(sh[1]), .y(st1[0]));
    mux2_1 m1_1(.d0(st0[1]), .d1(1'b0), .sel(sh[1]), .y(st1[1]));
    mux2_1 m1_2(.d0(st0[2]), .d1(st0[0]), .sel(sh[1]), .y(st1[2]));
    mux2_1 m1_3(.d0(st0[3]), .d1(st0[1]), .sel(sh[1]), .y(st1[3]));
    mux2_1 m1_4(.d0(st0[4]), .d1(st0[2]), .sel(sh[1]), .y(st1[4]));
    mux2_1 m1_5(.d0(st0[5]), .d1(st0[3]), .sel(sh[1]), .y(st1[5]));
    mux2_1 m1_6(.d0(st0[6]), .d1(st0[4]), .sel(sh[1]), .y(st1[6]));
    mux2_1 m1_7(.d0(st0[7]), .d1(st0[5]), .sel(sh[1]), .y(st1[7]));
    mux2_1 m1_8(.d0(st0[8]), .d1(st0[6]), .sel(sh[1]), .y(st1[8]));
    mux2_1 m1_9(.d0(st0[9]), .d1(st0[7]), .sel(sh[1]), .y(st1[9]));
    mux2_1 m1_10(.d0(st0[10]), .d1(st0[8]), .sel(sh[1]), .y(st1[10]));
    mux2_1 m1_11(.d0(st0[11]), .d1(st0[9]), .sel(sh[1]), .y(st1[11]));
    mux2_1 m1_12(.d0(st0[12]), .d1(st0[10]), .sel(sh[1]), .y(st1[12]));
    mux2_1 m1_13(.d0(st0[13]), .d1(st0[11]), .sel(sh[1]), .y(st1[13]));
    mux2_1 m1_14(.d0(st0[14]), .d1(st0[12]), .sel(sh[1]), .y(st1[14]));
    mux2_1 m1_15(.d0(st0[15]), .d1(st0[13]), .sel(sh[1]), .y(st1[15]));
    wire [15:0] st2;
    mux2_1 m2_0(.d0(st1[0]), .d1(1'b0), .sel(sh[2]), .y(st2[0]));
    mux2_1 m2_1(.d0(st1[1]), .d1(1'b0), .sel(sh[2]), .y(st2[1]));
    mux2_1 m2_2(.d0(st1[2]), .d1(1'b0), .sel(sh[2]), .y(st2[2]));
    mux2_1 m2_3(.d0(st1[3]), .d1(1'b0), .sel(sh[2]), .y(st2[3]));
    mux2_1 m2_4(.d0(st1[4]), .d1(st1[0]), .sel(sh[2]), .y(st2[4]));
    mux2_1 m2_5(.d0(st1[5]), .d1(st1[1]), .sel(sh[2]), .y(st2[5]));
    mux2_1 m2_6(.d0(st1[6]), .d1(st1[2]), .sel(sh[2]), .y(st2[6]));
    mux2_1 m2_7(.d0(st1[7]), .d1(st1[3]), .sel(sh[2]), .y(st2[7]));
    mux2_1 m2_8(.d0(st1[8]), .d1(st1[4]), .sel(sh[2]), .y(st2[8]));
    mux2_1 m2_9(.d0(st1[9]), .d1(st1[5]), .sel(sh[2]), .y(st2[9]));
    mux2_1 m2_10(.d0(st1[10]), .d1(st1[6]), .sel(sh[2]), .y(st2[10]));
    mux2_1 m2_11(.d0(st1[11]), .d1(st1[7]), .sel(sh[2]), .y(st2[11]));
    mux2_1 m2_12(.d0(st1[12]), .d1(st1[8]), .sel(sh[2]), .y(st2[12]));
    mux2_1 m2_13(.d0(st1[13]), .d1(st1[9]), .sel(sh[2]), .y(st2[13]));
    mux2_1 m2_14(.d0(st1[14]), .d1(st1[10]), .sel(sh[2]), .y(st2[14]));
    mux2_1 m2_15(.d0(st1[15]), .d1(st1[11]), .sel(sh[2]), .y(st2[15]));
    wire [15:0] st3;
    mux2_1 m3_0(.d0(st2[0]), .d1(1'b0), .sel(sh[3]), .y(st3[0]));
    mux2_1 m3_1(.d0(st2[1]), .d1(1'b0), .sel(sh[3]), .y(st3[1]));
    mux2_1 m3_2(.d0(st2[2]), .d1(1'b0), .sel(sh[3]), .y(st3[2]));
    mux2_1 m3_3(.d0(st2[3]), .d1(1'b0), .sel(sh[3]), .y(st3[3]));
    mux2_1 m3_4(.d0(st2[4]), .d1(1'b0), .sel(sh[3]), .y(st3[4]));
    mux2_1 m3_5(.d0(st2[5]), .d1(1'b0), .sel(sh[3]), .y(st3[5]));
    mux2_1 m3_6(.d0(st2[6]), .d1(1'b0), .sel(sh[3]), .y(st3[6]));
    mux2_1 m3_7(.d0(st2[7]), .d1(1'b0), .sel(sh[3]), .y(st3[7]));
    mux2_1 m3_8(.d0(st2[8]), .d1(st2[0]), .sel(sh[3]), .y(st3[8]));
    mux2_1 m3_9(.d0(st2[9]), .d1(st2[1]), .sel(sh[3]), .y(st3[9]));
    mux2_1 m3_10(.d0(st2[10]), .d1(st2[2]), .sel(sh[3]), .y(st3[10]));
    mux2_1 m3_11(.d0(st2[11]), .d1(st2[3]), .sel(sh[3]), .y(st3[11]));
    mux2_1 m3_12(.d0(st2[12]), .d1(st2[4]), .sel(sh[3]), .y(st3[12]));
    mux2_1 m3_13(.d0(st2[13]), .d1(st2[5]), .sel(sh[3]), .y(st3[13]));
    mux2_1 m3_14(.d0(st2[14]), .d1(st2[6]), .sel(sh[3]), .y(st3[14]));
    mux2_1 m3_15(.d0(st2[15]), .d1(st2[7]), .sel(sh[3]), .y(st3[15]));
    assign y = st3;
endmodule

module mux2_1(input d0, input d1, input sel, output y);
    assign y = sel ? d1 : d0;
endmodule


