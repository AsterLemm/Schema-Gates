// =====================================================================
//  add_knowles8.v
//  8-bit prefix adder.
//  Knowles (Kogge-Stone-class prefix).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_knowles8(input [7:0] a, input [7:0] b, input cin, output [7:0] sum, output cout);
    // define a input 80.160.255   // define b input 80.200.255
    // define cin input 255.230.80   // define sum output 120.255.160   // define cout output 255.120.120
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
    black_cell bc_l0_2(.gk(g0[2]), .pk(p0[2]), .gj(g0[1]), .pj(p0[1]), .g(g1[2]), .p(p1[2]));
    black_cell bc_l0_3(.gk(g0[3]), .pk(p0[3]), .gj(g0[2]), .pj(p0[2]), .g(g1[3]), .p(p1[3]));
    black_cell bc_l0_4(.gk(g0[4]), .pk(p0[4]), .gj(g0[3]), .pj(p0[3]), .g(g1[4]), .p(p1[4]));
    black_cell bc_l0_5(.gk(g0[5]), .pk(p0[5]), .gj(g0[4]), .pj(p0[4]), .g(g1[5]), .p(p1[5]));
    black_cell bc_l0_6(.gk(g0[6]), .pk(p0[6]), .gj(g0[5]), .pj(p0[5]), .g(g1[6]), .p(p1[6]));
    black_cell bc_l0_7(.gk(g0[7]), .pk(p0[7]), .gj(g0[6]), .pj(p0[6]), .g(g1[7]), .p(p1[7]));
    wire [7:0] g2, p2;
    assign g2[0] = g1[0]; assign p2[0] = p1[0];
    assign g2[1] = g1[1]; assign p2[1] = p1[1];
    black_cell bc_l1_2(.gk(g1[2]), .pk(p1[2]), .gj(g1[0]), .pj(p1[0]), .g(g2[2]), .p(p2[2]));
    black_cell bc_l1_3(.gk(g1[3]), .pk(p1[3]), .gj(g1[1]), .pj(p1[1]), .g(g2[3]), .p(p2[3]));
    black_cell bc_l1_4(.gk(g1[4]), .pk(p1[4]), .gj(g1[2]), .pj(p1[2]), .g(g2[4]), .p(p2[4]));
    black_cell bc_l1_5(.gk(g1[5]), .pk(p1[5]), .gj(g1[3]), .pj(p1[3]), .g(g2[5]), .p(p2[5]));
    black_cell bc_l1_6(.gk(g1[6]), .pk(p1[6]), .gj(g1[4]), .pj(p1[4]), .g(g2[6]), .p(p2[6]));
    black_cell bc_l1_7(.gk(g1[7]), .pk(p1[7]), .gj(g1[5]), .pj(p1[5]), .g(g2[7]), .p(p2[7]));
    wire [7:0] g3, p3;
    assign g3[0] = g2[0]; assign p3[0] = p2[0];
    assign g3[1] = g2[1]; assign p3[1] = p2[1];
    assign g3[2] = g2[2]; assign p3[2] = p2[2];
    assign g3[3] = g2[3]; assign p3[3] = p2[3];
    black_cell bc_l2_4(.gk(g2[4]), .pk(p2[4]), .gj(g2[0]), .pj(p2[0]), .g(g3[4]), .p(p3[4]));
    black_cell bc_l2_5(.gk(g2[5]), .pk(p2[5]), .gj(g2[1]), .pj(p2[1]), .g(g3[5]), .p(p3[5]));
    black_cell bc_l2_6(.gk(g2[6]), .pk(p2[6]), .gj(g2[2]), .pj(p2[2]), .g(g3[6]), .p(p3[6]));
    black_cell bc_l2_7(.gk(g2[7]), .pk(p2[7]), .gj(g2[3]), .pj(p2[3]), .g(g3[7]), .p(p3[7]));
    wire [8:0] carry; assign carry[0] = cin;
    assign carry[1] = g3[0] | (p3[0] & cin);
    assign carry[2] = g3[1] | (p3[1] & cin);
    assign carry[3] = g3[2] | (p3[2] & cin);
    assign carry[4] = g3[3] | (p3[3] & cin);
    assign carry[5] = g3[4] | (p3[4] & cin);
    assign carry[6] = g3[5] | (p3[5] & cin);
    assign carry[7] = g3[6] | (p3[6] & cin);
    assign carry[8] = g3[7] | (p3[7] & cin);
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


