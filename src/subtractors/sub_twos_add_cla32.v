// =====================================================================
//  sub_twos_add_cla32.v
//  32-bit subtractor via two's complement on CLA core.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sub_twos_add_cla32(input [31:0] a, input [31:0] b, output [31:0] diff, output bout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define diff output 120.255.160
    // define bout output 255.120.120
    wire cout;
    add_cla_unit32 u(.a(a), .b(~b), .cin(1'b1), .sum(diff), .cout(cout));
    assign bout = ~cout;
endmodule

module add_cla_unit32(input [31:0] a, input [31:0] b, input cin, output [31:0] sum, output cout);
    wire [8:0] c; assign c[0]=cin;
    cla4u blk0(.a(a[3:0]),.b(b[3:0]),.cin(c[0]),.sum(sum[3:0]),.cout(c[1]));
    cla4u blk1(.a(a[7:4]),.b(b[7:4]),.cin(c[1]),.sum(sum[7:4]),.cout(c[2]));
    cla4u blk2(.a(a[11:8]),.b(b[11:8]),.cin(c[2]),.sum(sum[11:8]),.cout(c[3]));
    cla4u blk3(.a(a[15:12]),.b(b[15:12]),.cin(c[3]),.sum(sum[15:12]),.cout(c[4]));
    cla4u blk4(.a(a[19:16]),.b(b[19:16]),.cin(c[4]),.sum(sum[19:16]),.cout(c[5]));
    cla4u blk5(.a(a[23:20]),.b(b[23:20]),.cin(c[5]),.sum(sum[23:20]),.cout(c[6]));
    cla4u blk6(.a(a[27:24]),.b(b[27:24]),.cin(c[6]),.sum(sum[27:24]),.cout(c[7]));
    cla4u blk7(.a(a[31:28]),.b(b[31:28]),.cin(c[7]),.sum(sum[31:28]),.cout(c[8]));
    assign cout=c[8];
endmodule

module cla4u(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    wire [3:0] p=a^b, g=a&b; wire c0,c1,c2,c3; assign c0=cin;
    assign c1=g[0]|(p[0]&c0);
    assign c2=g[1]|(p[1]&g[0])|(p[1]&p[0]&c0);
    assign c3=g[2]|(p[2]&g[1])|(p[2]&p[1]&g[0])|(p[2]&p[1]&p[0]&c0);
    assign cout=g[3]|(p[3]&g[2])|(p[3]&p[2]&g[1])|(p[3]&p[2]&p[1]&g[0])|(p[3]&p[2]&p[1]&p[0]&c0);
    assign sum[0]=p[0]^c0;assign sum[1]=p[1]^c1;assign sum[2]=p[2]^c2;assign sum[3]=p[3]^c3;
endmodule


