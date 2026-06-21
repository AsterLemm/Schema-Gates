// =====================================================================
//  add_cla16.v
//  16-bit CLA: 4 x cla4 blocks + group lookahead.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_cla16(input [15:0] a, input [15:0] b, input cin, output [15:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define cin input 255.230.80
    // define sum output 120.255.160
    // define cout output 255.120.120
    wire [3:0] gp, gg;
    wire [4:0] carry; assign carry[0]=cin;
    cla4_blk blk0(.a(a[3:0]), .b(b[3:0]), .cin(carry[0]), .sum(sum[3:0]), .gp(gp[0]), .gg(gg[0]));
    cla4_blk blk1(.a(a[7:4]), .b(b[7:4]), .cin(carry[1]), .sum(sum[7:4]), .gp(gp[1]), .gg(gg[1]));
    cla4_blk blk2(.a(a[11:8]), .b(b[11:8]), .cin(carry[2]), .sum(sum[11:8]), .gp(gp[2]), .gg(gg[2]));
    cla4_blk blk3(.a(a[15:12]), .b(b[15:12]), .cin(carry[3]), .sum(sum[15:12]), .gp(gp[3]), .gg(gg[3]));
    assign carry[1] = gg[0] | (gp[0] & carry[0]);
    assign carry[2] = gg[1] | (gp[1] & carry[1]);
    assign carry[3] = gg[2] | (gp[2] & carry[2]);
    assign carry[4] = gg[3] | (gp[3] & carry[3]);
    assign cout = carry[4];
endmodule

module cla4_blk(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output gp, output gg);
    wire [3:0] p,g;
    pg_bit pg0(.a(a[0]),.b(b[0]),.p(p[0]),.g(g[0]));
    pg_bit pg1(.a(a[1]),.b(b[1]),.p(p[1]),.g(g[1]));
    pg_bit pg2(.a(a[2]),.b(b[2]),.p(p[2]),.g(g[2]));
    pg_bit pg3(.a(a[3]),.b(b[3]),.p(p[3]),.g(g[3]));
    wire c0,c1,c2,c3; assign c0=cin;
    assign c1 = g[0] | (p[0]&c0);
    assign c2 = g[1] | (p[1]&g[0]) | (p[1]&p[0]&c0);
    assign c3 = g[2] | (p[2]&g[1]) | (p[2]&p[1]&g[0]) | (p[2]&p[1]&p[0]&c0);
    assign sum[0]=p[0]^c0; assign sum[1]=p[1]^c1; assign sum[2]=p[2]^c2; assign sum[3]=p[3]^c3;
    assign gp = &p;                       // group propagate
    assign gg = g[3] | (p[3]&g[2]) | (p[3]&p[2]&g[1]) | (p[3]&p[2]&p[1]&g[0]);  // group generate
endmodule

module pg_bit(input a, input b, output p, output g);
    assign p = a ^ b;
    assign g = a & b;
endmodule


