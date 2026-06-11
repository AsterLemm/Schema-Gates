// =====================================================================
//  add_cla4.v
//  4-bit carry-lookahead adder (flat lookahead carries).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_cla4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    // define a input 80.160.255   // define b input 80.200.255
    // define cin input 255.230.80   // define sum output 120.255.160   // define cout output 255.120.120
    wire [3:0] p,g;
    pg_bit pg0(.a(a[0]),.b(b[0]),.p(p[0]),.g(g[0]));
    pg_bit pg1(.a(a[1]),.b(b[1]),.p(p[1]),.g(g[1]));
    pg_bit pg2(.a(a[2]),.b(b[2]),.p(p[2]),.g(g[2]));
    pg_bit pg3(.a(a[3]),.b(b[3]),.p(p[3]),.g(g[3]));
    wire c0,c1,c2,c3; assign c0=cin;
    assign c1 = g[0] | (p[0]&c0);
    assign c2 = g[1] | (p[1]&g[0]) | (p[1]&p[0]&c0);
    assign c3 = g[2] | (p[2]&g[1]) | (p[2]&p[1]&g[0]) | (p[2]&p[1]&p[0]&c0);
    assign cout = g[3] | (p[3]&g[2]) | (p[3]&p[2]&g[1]) | (p[3]&p[2]&p[1]&g[0]) | (p[3]&p[2]&p[1]&p[0]&c0);
    assign sum[0]=p[0]^c0; assign sum[1]=p[1]^c1; assign sum[2]=p[2]^c2; assign sum[3]=p[3]^c3;
endmodule

module pg_bit(input a, input b, output p, output g);
    assign p = a ^ b;
    assign g = a & b;
endmodule


