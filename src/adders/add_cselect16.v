// =====================================================================
//  add_cselect16.v
//  16-bit carry-select: each 4-bit block computed for cin=0 and 1, then muxed.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_cselect16(input [15:0] a, input [15:0] b, input cin, output [15:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define cin input 255.230.80
    // define sum output 120.255.160
    // define cout output 255.120.120
    wire [4:0] c; assign c[0]=cin;
    wire co0_0;
    add_rc4_unit blk0(.a(a[3:0]),.b(b[3:0]),.cin(c[0]),.sum(sum[3:0]),.cout(co0_0));
    assign c[1]=co0_0;
    wire [3:0] s0_1, s1_1; wire co0_1, co1_1;
    add_rc4_unit blk1_0(.a(a[7:4]),.b(b[7:4]),.cin(1'b0),.sum(s0_1),.cout(co0_1));
    add_rc4_unit blk1_1(.a(a[7:4]),.b(b[7:4]),.cin(1'b1),.sum(s1_1),.cout(co1_1));
    assign sum[7:4] = c[1] ? s1_1 : s0_1;
    assign c[2]       = c[1] ? co1_1 : co0_1;
    wire [3:0] s0_2, s1_2; wire co0_2, co1_2;
    add_rc4_unit blk2_0(.a(a[11:8]),.b(b[11:8]),.cin(1'b0),.sum(s0_2),.cout(co0_2));
    add_rc4_unit blk2_1(.a(a[11:8]),.b(b[11:8]),.cin(1'b1),.sum(s1_2),.cout(co1_2));
    assign sum[11:8] = c[2] ? s1_2 : s0_2;
    assign c[3]       = c[2] ? co1_2 : co0_2;
    wire [3:0] s0_3, s1_3; wire co0_3, co1_3;
    add_rc4_unit blk3_0(.a(a[15:12]),.b(b[15:12]),.cin(1'b0),.sum(s0_3),.cout(co0_3));
    add_rc4_unit blk3_1(.a(a[15:12]),.b(b[15:12]),.cin(1'b1),.sum(s1_3),.cout(co1_3));
    assign sum[15:12] = c[3] ? s1_3 : s0_3;
    assign c[4]       = c[3] ? co1_3 : co0_3;
    assign cout=c[4];
endmodule

module add_rc4_unit(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    wire [4:0] c; assign c[0]=cin;
    full_adder fa0(.a(a[0]),.b(b[0]),.cin(c[0]),.sum(sum[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(b[1]),.cin(c[1]),.sum(sum[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(b[2]),.cin(c[2]),.sum(sum[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(b[3]),.cin(c[3]),.sum(sum[3]),.cout(c[4]));
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


