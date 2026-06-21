// =====================================================================
//  add_knowles4.v
//  4-bit prefix adder.
//  Knowles (Kogge-Stone-class prefix).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_knowles4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define cin input 255.230.80
    // define sum output 120.255.160
    // define cout output 255.120.120
    wire [3:0] p0, g0;
    assign p0[0] = a[0] ^ b[0];
    assign g0[0] = a[0] & b[0];
    assign p0[1] = a[1] ^ b[1];
    assign g0[1] = a[1] & b[1];
    assign p0[2] = a[2] ^ b[2];
    assign g0[2] = a[2] & b[2];
    assign p0[3] = a[3] ^ b[3];
    assign g0[3] = a[3] & b[3];
    wire [3:0] g1, p1;
    assign g1[0] = g0[0]; assign p1[0] = p0[0];
    black_cell bc_l0_1(.gk(g0[1]), .pk(p0[1]), .gj(g0[0]), .pj(p0[0]), .g(g1[1]), .p(p1[1]));
    black_cell bc_l0_2(.gk(g0[2]), .pk(p0[2]), .gj(g0[1]), .pj(p0[1]), .g(g1[2]), .p(p1[2]));
    black_cell bc_l0_3(.gk(g0[3]), .pk(p0[3]), .gj(g0[2]), .pj(p0[2]), .g(g1[3]), .p(p1[3]));
    wire [3:0] g2, p2;
    assign g2[0] = g1[0]; assign p2[0] = p1[0];
    assign g2[1] = g1[1]; assign p2[1] = p1[1];
    black_cell bc_l1_2(.gk(g1[2]), .pk(p1[2]), .gj(g1[0]), .pj(p1[0]), .g(g2[2]), .p(p2[2]));
    black_cell bc_l1_3(.gk(g1[3]), .pk(p1[3]), .gj(g1[1]), .pj(p1[1]), .g(g2[3]), .p(p2[3]));
    wire [4:0] carry; assign carry[0] = cin;
    assign carry[1] = g2[0] | (p2[0] & cin);
    assign carry[2] = g2[1] | (p2[1] & cin);
    assign carry[3] = g2[2] | (p2[2] & cin);
    assign carry[4] = g2[3] | (p2[3] & cin);
    assign cout = carry[4];
    assign sum[0] = p0[0] ^ carry[0];
    assign sum[1] = p0[1] ^ carry[1];
    assign sum[2] = p0[2] ^ carry[2];
    assign sum[3] = p0[3] ^ carry[3];
endmodule

module black_cell(input gk, input pk, input gj, input pj, output g, output p);
    assign g = gk | (pk & gj);
    assign p = pk & pj;
endmodule


