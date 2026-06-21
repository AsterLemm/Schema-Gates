// =====================================================================
//  sub_cskip16.v
//  16-bit subtractor (two's complement on carry-skip adder).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sub_cskip16(input [15:0] a, input [15:0] b, output [15:0] diff, output bout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define diff output 120.255.160
    // define bout output 255.120.120
    wire cout; addskip_unit16 u(.a(a),.b(~b),.cin(1'b1),.sum(diff),.cout(cout));
    assign bout=~cout;
endmodule

module addskip_unit16(input [15:0] a, input [15:0] b, input cin, output [15:0] sum, output cout);
    wire [4:0] c; assign c[0]=cin;
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
    assign cout=c[4];
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


