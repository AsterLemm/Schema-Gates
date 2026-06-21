// =====================================================================
//  sub_cskip32.v
//  32-bit subtractor (two's complement on carry-skip adder).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sub_cskip32(input [31:0] a, input [31:0] b, output [31:0] diff, output bout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define diff output 120.255.160
    // define bout output 255.120.120
    wire cout; addskip_unit32 u(.a(a),.b(~b),.cin(1'b1),.sum(diff),.cout(cout));
    assign bout=~cout;
endmodule

module addskip_unit32(input [31:0] a, input [31:0] b, input cin, output [31:0] sum, output cout);
    wire [8:0] c; assign c[0]=cin;
    wire [3:0] pp0=a[3:0]^b[3:0]; wire bp0=&pp0; wire rc0;
    rc4u u0(.a(a[3:0]),.b(b[3:0]),.cin(c[0]),.sum(sum[3:0]),.cout(rc0));
    assign c[1]=bp0?c[0]:rc0;
    wire [3:0] pp1=a[7:4]^b[7:4]; wire bp1=&pp1; wire rc1;
    rc4u u1(.a(a[7:4]),.b(b[7:4]),.cin(c[1]),.sum(sum[7:4]),.cout(rc1));
    assign c[2]=bp1?c[1]:rc1;
    wire [3:0] pp2=a[11:8]^b[11:8]; wire bp2=&pp2; wire rc2;
    rc4u u2(.a(a[11:8]),.b(b[11:8]),.cin(c[2]),.sum(sum[11:8]),.cout(rc2));
    assign c[3]=bp2?c[2]:rc2;
    wire [3:0] pp3=a[15:12]^b[15:12]; wire bp3=&pp3; wire rc3;
    rc4u u3(.a(a[15:12]),.b(b[15:12]),.cin(c[3]),.sum(sum[15:12]),.cout(rc3));
    assign c[4]=bp3?c[3]:rc3;
    wire [3:0] pp4=a[19:16]^b[19:16]; wire bp4=&pp4; wire rc4;
    rc4u u4(.a(a[19:16]),.b(b[19:16]),.cin(c[4]),.sum(sum[19:16]),.cout(rc4));
    assign c[5]=bp4?c[4]:rc4;
    wire [3:0] pp5=a[23:20]^b[23:20]; wire bp5=&pp5; wire rc5;
    rc4u u5(.a(a[23:20]),.b(b[23:20]),.cin(c[5]),.sum(sum[23:20]),.cout(rc5));
    assign c[6]=bp5?c[5]:rc5;
    wire [3:0] pp6=a[27:24]^b[27:24]; wire bp6=&pp6; wire rc6;
    rc4u u6(.a(a[27:24]),.b(b[27:24]),.cin(c[6]),.sum(sum[27:24]),.cout(rc6));
    assign c[7]=bp6?c[6]:rc6;
    wire [3:0] pp7=a[31:28]^b[31:28]; wire bp7=&pp7; wire rc7;
    rc4u u7(.a(a[31:28]),.b(b[31:28]),.cin(c[7]),.sum(sum[31:28]),.cout(rc7));
    assign c[8]=bp7?c[7]:rc7;
    assign cout=c[8];
endmodule

module rc4u(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    wire [4:0] c; assign c[0]=cin;
    full_adder f0(.a(a[0]),.b(b[0]),.cin(c[0]),.sum(sum[0]),.cout(c[1]));
    full_adder f1(.a(a[1]),.b(b[1]),.cin(c[1]),.sum(sum[1]),.cout(c[2]));
    full_adder f2(.a(a[2]),.b(b[2]),.cin(c[2]),.sum(sum[2]),.cout(c[3]));
    full_adder f3(.a(a[3]),.b(b[3]),.cin(c[3]),.sum(sum[3]),.cout(c[4]));
    assign cout=c[4];
endmodule

module full_adder(input a, input b, input cin, output sum, output cout);
    wire s0, c0, c1;
    half_adder ha0(.a(a),  .b(b),   .sum(s0),  .carry(c0));
    half_adder ha1(.a(s0), .b(cin), .sum(sum), .carry(c1));
    assign cout = c0 | c1;
endmodule

module half_adder(input a, input b, output sum, output carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule


