// =====================================================================
//  addsub_cla8.v
//  8-bit add/sub on CLA core.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module addsub_cla8(input [7:0] a, input [7:0] b, input sub, output [7:0] result, output cout, output ovf);
    // define a input 80.160.255   // define b input 80.200.255   // define sub input 200.120.255
    // define result output 120.255.160   // define cout output 255.120.120   // define ovf output 255.255.255
    wire [7:0] bx = b ^ {8{sub}};
    wire co;
    claadd8 u(.a(a),.b(bx),.cin(sub),.sum(result),.cout(co));
    assign cout=co; assign ovf=(a[7]==bx[7])&(result[7]!=a[7]);
endmodule

module claadd8(input [7:0] a, input [7:0] b, input cin, output [7:0] sum, output cout);
    wire [2:0] c; assign c[0]=cin;
    cla4z blk0(.a(a[3:0]),.b(b[3:0]),.cin(c[0]),.sum(sum[3:0]),.cout(c[1]));
    cla4z blk1(.a(a[7:4]),.b(b[7:4]),.cin(c[1]),.sum(sum[7:4]),.cout(c[2]));
    assign cout=c[2];
endmodule

module cla4z(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    wire [3:0] p=a^b, g=a&b; wire c0,c1,c2,c3; assign c0=cin;
    assign c1=g[0]|(p[0]&c0);assign c2=g[1]|(p[1]&g[0])|(p[1]&p[0]&c0);
    assign c3=g[2]|(p[2]&g[1])|(p[2]&p[1]&g[0])|(p[2]&p[1]&p[0]&c0);
    assign cout=g[3]|(p[3]&g[2])|(p[3]&p[2]&g[1])|(p[3]&p[2]&p[1]&g[0])|(p[3]&p[2]&p[1]&p[0]&c0);
    assign sum[0]=p[0]^c0;assign sum[1]=p[1]^c1;assign sum[2]=p[2]^c2;assign sum[3]=p[3]^c3;
endmodule


