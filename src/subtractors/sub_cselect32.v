// =====================================================================
//  sub_cselect32.v
//  32-bit subtractor (two's complement on carry-select adder).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sub_cselect32(input [31:0] a, input [31:0] b, output [31:0] diff, output bout);
    // define a input 80.160.255   // define b input 80.200.255   // define diff output 120.255.160   // define bout output 255.120.120
    wire cout; addsel_unit32 u(.a(a),.b(~b),.cin(1'b1),.sum(diff),.cout(cout));
    assign bout=~cout;
endmodule

module addsel_unit32(input [31:0] a, input [31:0] b, input cin, output [31:0] sum, output cout);
    wire [8:0] c; assign c[0]=cin;
    wire rc0; rc4s u0(.a(a[3:0]),.b(b[3:0]),.cin(c[0]),.sum(sum[3:0]),.cout(rc0)); assign c[1]=rc0;
    wire [3:0] s01,s11; wire co01,co11;
    rc4s u1a(.a(a[7:4]),.b(b[7:4]),.cin(1'b0),.sum(s01),.cout(co01));
    rc4s u1b(.a(a[7:4]),.b(b[7:4]),.cin(1'b1),.sum(s11),.cout(co11));
    assign sum[7:4]=c[1]?s11:s01; assign c[2]=c[1]?co11:co01;
    wire [3:0] s02,s12; wire co02,co12;
    rc4s u2a(.a(a[11:8]),.b(b[11:8]),.cin(1'b0),.sum(s02),.cout(co02));
    rc4s u2b(.a(a[11:8]),.b(b[11:8]),.cin(1'b1),.sum(s12),.cout(co12));
    assign sum[11:8]=c[2]?s12:s02; assign c[3]=c[2]?co12:co02;
    wire [3:0] s03,s13; wire co03,co13;
    rc4s u3a(.a(a[15:12]),.b(b[15:12]),.cin(1'b0),.sum(s03),.cout(co03));
    rc4s u3b(.a(a[15:12]),.b(b[15:12]),.cin(1'b1),.sum(s13),.cout(co13));
    assign sum[15:12]=c[3]?s13:s03; assign c[4]=c[3]?co13:co03;
    wire [3:0] s04,s14; wire co04,co14;
    rc4s u4a(.a(a[19:16]),.b(b[19:16]),.cin(1'b0),.sum(s04),.cout(co04));
    rc4s u4b(.a(a[19:16]),.b(b[19:16]),.cin(1'b1),.sum(s14),.cout(co14));
    assign sum[19:16]=c[4]?s14:s04; assign c[5]=c[4]?co14:co04;
    wire [3:0] s05,s15; wire co05,co15;
    rc4s u5a(.a(a[23:20]),.b(b[23:20]),.cin(1'b0),.sum(s05),.cout(co05));
    rc4s u5b(.a(a[23:20]),.b(b[23:20]),.cin(1'b1),.sum(s15),.cout(co15));
    assign sum[23:20]=c[5]?s15:s05; assign c[6]=c[5]?co15:co05;
    wire [3:0] s06,s16; wire co06,co16;
    rc4s u6a(.a(a[27:24]),.b(b[27:24]),.cin(1'b0),.sum(s06),.cout(co06));
    rc4s u6b(.a(a[27:24]),.b(b[27:24]),.cin(1'b1),.sum(s16),.cout(co16));
    assign sum[27:24]=c[6]?s16:s06; assign c[7]=c[6]?co16:co06;
    wire [3:0] s07,s17; wire co07,co17;
    rc4s u7a(.a(a[31:28]),.b(b[31:28]),.cin(1'b0),.sum(s07),.cout(co07));
    rc4s u7b(.a(a[31:28]),.b(b[31:28]),.cin(1'b1),.sum(s17),.cout(co17));
    assign sum[31:28]=c[7]?s17:s07; assign c[8]=c[7]?co17:co07;
    assign cout=c[8];
endmodule

module rc4s(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
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


