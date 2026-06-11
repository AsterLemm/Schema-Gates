// =====================================================================
//  addsub_cla16.v
//  16-bit add/sub on CLA core.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module addsub_cla16(input [15:0] a, input [15:0] b, input sub, output [15:0] result, output cout, output ovf);
    // define a input 80.160.255   // define b input 80.200.255   // define sub input 200.120.255
    // define result output 120.255.160   // define cout output 255.120.120   // define ovf output 255.255.255
    wire [15:0] bx = b ^ {16{sub}};
    wire co;
    claadd16 u(.a(a),.b(bx),.cin(sub),.sum(result),.cout(co));
    assign cout=co; assign ovf=(a[15]==bx[15])&(result[15]!=a[15]);
endmodule

module claadd16(input [15:0] a, input [15:0] b, input cin, output [15:0] sum, output cout);
    wire [4:0] c; assign c[0]=cin;
    cla4z blk0(.a(a[3:0]),.b(b[3:0]),.cin(c[0]),.sum(sum[3:0]),.cout(c[1]));
    cla4z blk1(.a(a[7:4]),.b(b[7:4]),.cin(c[1]),.sum(sum[7:4]),.cout(c[2]));
    cla4z blk2(.a(a[11:8]),.b(b[11:8]),.cin(c[2]),.sum(sum[11:8]),.cout(c[3]));
    cla4z blk3(.a(a[15:12]),.b(b[15:12]),.cin(c[3]),.sum(sum[15:12]),.cout(c[4]));
    assign cout=c[4];
endmodule

module cla4z(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    wire [3:0] p=a^b, g=a&b; wire c0,c1,c2,c3; assign c0=cin;
    assign c1=g[0]|(p[0]&c0);assign c2=g[1]|(p[1]&g[0])|(p[1]&p[0]&c0);
    assign c3=g[2]|(p[2]&g[1])|(p[2]&p[1]&g[0])|(p[2]&p[1]&p[0]&c0);
    assign cout=g[3]|(p[3]&g[2])|(p[3]&p[2]&g[1])|(p[3]&p[2]&p[1]&g[0])|(p[3]&p[2]&p[1]&p[0]&c0);
    assign sum[0]=p[0]^c0;assign sum[1]=p[1]^c1;assign sum[2]=p[2]^c2;assign sum[3]=p[3]^c3;
endmodule


