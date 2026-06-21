// =====================================================================
//  add_brent_kung8.v
//  8-bit prefix adder.
//  Brent-Kung (up-sweep + down-sweep, minimal cells).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_brent_kung8(input [7:0] a, input [7:0] b, input cin, output [7:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define cin input 255.230.80
    // define sum output 120.255.160
    // define cout output 255.120.120
    wire [7:0] p0, g0;
    assign p0[0] = a[0] ^ b[0];
    assign g0[0] = a[0] & b[0];
    assign p0[1] = a[1] ^ b[1];
    assign g0[1] = a[1] & b[1];
    assign p0[2] = a[2] ^ b[2];
    assign g0[2] = a[2] & b[2];
    assign p0[3] = a[3] ^ b[3];
    assign g0[3] = a[3] & b[3];
    assign p0[4] = a[4] ^ b[4];
    assign g0[4] = a[4] & b[4];
    assign p0[5] = a[5] ^ b[5];
    assign g0[5] = a[5] & b[5];
    assign p0[6] = a[6] ^ b[6];
    assign g0[6] = a[6] & b[6];
    assign p0[7] = a[7] ^ b[7];
    assign g0[7] = a[7] & b[7];
    wire [7:0] g1, p1;
    assign g1[0] = g0[0]; assign p1[0] = p0[0];
    black_cell bc_l0_1(.gk(g0[1]), .pk(p0[1]), .gj(g0[0]), .pj(p0[0]), .g(g1[1]), .p(p1[1]));
    assign g1[2] = g0[2]; assign p1[2] = p0[2];
    black_cell bc_l0_3(.gk(g0[3]), .pk(p0[3]), .gj(g0[2]), .pj(p0[2]), .g(g1[3]), .p(p1[3]));
    assign g1[4] = g0[4]; assign p1[4] = p0[4];
    black_cell bc_l0_5(.gk(g0[5]), .pk(p0[5]), .gj(g0[4]), .pj(p0[4]), .g(g1[5]), .p(p1[5]));
    assign g1[6] = g0[6]; assign p1[6] = p0[6];
    black_cell bc_l0_7(.gk(g0[7]), .pk(p0[7]), .gj(g0[6]), .pj(p0[6]), .g(g1[7]), .p(p1[7]));
    wire [7:0] g2, p2;
    assign g2[0] = g1[0]; assign p2[0] = p1[0];
    assign g2[1] = g1[1]; assign p2[1] = p1[1];
    assign g2[2] = g1[2]; assign p2[2] = p1[2];
    black_cell bc_l1_3(.gk(g1[3]), .pk(p1[3]), .gj(g1[1]), .pj(p1[1]), .g(g2[3]), .p(p2[3]));
    assign g2[4] = g1[4]; assign p2[4] = p1[4];
    assign g2[5] = g1[5]; assign p2[5] = p1[5];
    assign g2[6] = g1[6]; assign p2[6] = p1[6];
    black_cell bc_l1_7(.gk(g1[7]), .pk(p1[7]), .gj(g1[5]), .pj(p1[5]), .g(g2[7]), .p(p2[7]));
    wire [7:0] g3, p3;
    assign g3[0] = g2[0]; assign p3[0] = p2[0];
    assign g3[1] = g2[1]; assign p3[1] = p2[1];
    assign g3[2] = g2[2]; assign p3[2] = p2[2];
    assign g3[3] = g2[3]; assign p3[3] = p2[3];
    assign g3[4] = g2[4]; assign p3[4] = p2[4];
    assign g3[5] = g2[5]; assign p3[5] = p2[5];
    assign g3[6] = g2[6]; assign p3[6] = p2[6];
    black_cell bc_l2_7(.gk(g2[7]), .pk(p2[7]), .gj(g2[3]), .pj(p2[3]), .g(g3[7]), .p(p3[7]));
    wire [7:0] g4, p4;
    assign g4[0] = g3[0]; assign p4[0] = p3[0];
    assign g4[1] = g3[1]; assign p4[1] = p3[1];
    assign g4[2] = g3[2]; assign p4[2] = p3[2];
    assign g4[3] = g3[3]; assign p4[3] = p3[3];
    assign g4[4] = g3[4]; assign p4[4] = p3[4];
    black_cell bc_l3_5(.gk(g3[5]), .pk(p3[5]), .gj(g3[3]), .pj(p3[3]), .g(g4[5]), .p(p4[5]));
    assign g4[6] = g3[6]; assign p4[6] = p3[6];
    assign g4[7] = g3[7]; assign p4[7] = p3[7];
    wire [7:0] g5, p5;
    assign g5[0] = g4[0]; assign p5[0] = p4[0];
    assign g5[1] = g4[1]; assign p5[1] = p4[1];
    black_cell bc_l4_2(.gk(g4[2]), .pk(p4[2]), .gj(g4[1]), .pj(p4[1]), .g(g5[2]), .p(p5[2]));
    assign g5[3] = g4[3]; assign p5[3] = p4[3];
    black_cell bc_l4_4(.gk(g4[4]), .pk(p4[4]), .gj(g4[3]), .pj(p4[3]), .g(g5[4]), .p(p5[4]));
    assign g5[5] = g4[5]; assign p5[5] = p4[5];
    black_cell bc_l4_6(.gk(g4[6]), .pk(p4[6]), .gj(g4[5]), .pj(p4[5]), .g(g5[6]), .p(p5[6]));
    assign g5[7] = g4[7]; assign p5[7] = p4[7];
    wire [8:0] carry; assign carry[0] = cin;
    assign carry[1] = g5[0] | (p5[0] & cin);
    assign carry[2] = g5[1] | (p5[1] & cin);
    assign carry[3] = g5[2] | (p5[2] & cin);
    assign carry[4] = g5[3] | (p5[3] & cin);
    assign carry[5] = g5[4] | (p5[4] & cin);
    assign carry[6] = g5[5] | (p5[5] & cin);
    assign carry[7] = g5[6] | (p5[6] & cin);
    assign carry[8] = g5[7] | (p5[7] & cin);
    assign cout = carry[8];
    assign sum[0] = p0[0] ^ carry[0];
    assign sum[1] = p0[1] ^ carry[1];
    assign sum[2] = p0[2] ^ carry[2];
    assign sum[3] = p0[3] ^ carry[3];
    assign sum[4] = p0[4] ^ carry[4];
    assign sum[5] = p0[5] ^ carry[5];
    assign sum[6] = p0[6] ^ carry[6];
    assign sum[7] = p0[7] ^ carry[7];
endmodule

module black_cell(input gk, input pk, input gj, input pj, output g, output p);
    assign g = gk | (pk & gj);
    assign p = pk & pj;
endmodule


