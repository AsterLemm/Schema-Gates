// =====================================================================
//  add_block_cla4.v
//  4-bit block-CLA (single CLA block).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_block_cla4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define cin input 255.230.80
    // define sum output 120.255.160
    // define cout output 255.120.120
    add_cla4_unit blk0(.a(a),.b(b),.cin(cin),.sum(sum),.cout(cout));
endmodule

module add_cla4_unit(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    wire [3:0] p,g; wire c0,c1,c2,c3; assign c0=cin;
    assign p=a^b; assign g=a&b;
    assign c1=g[0]|(p[0]&c0);
    assign c2=g[1]|(p[1]&g[0])|(p[1]&p[0]&c0);
    assign c3=g[2]|(p[2]&g[1])|(p[2]&p[1]&g[0])|(p[2]&p[1]&p[0]&c0);
    assign cout=g[3]|(p[3]&g[2])|(p[3]&p[2]&g[1])|(p[3]&p[2]&p[1]&g[0])|(p[3]&p[2]&p[1]&p[0]&c0);
    assign sum[0]=p[0]^c0;assign sum[1]=p[1]^c1;assign sum[2]=p[2]^c2;assign sum[3]=p[3]^c3;
endmodule


