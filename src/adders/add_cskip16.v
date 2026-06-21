// =====================================================================
//  add_cskip16.v
//  16-bit carry-skip: 4-bit ripple blocks, carry skips fully-propagating blocks.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_cskip16(input [15:0] a, input [15:0] b, input cin, output [15:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define cin input 255.230.80
    // define sum output 120.255.160
    // define cout output 255.120.120
    wire [4:0] c; assign c[0]=cin;
    wire [3:0] p0 = a[3:0] ^ b[3:0];
    wire blkp0 = &p0;                  // block propagate
    wire rcout0;
    add_rc4_unit u0(.a(a[3:0]),.b(b[3:0]),.cin(c[0]),.sum(sum[3:0]),.cout(rcout0));
    assign c[1] = blkp0 ? c[0] : rcout0;   // skip carry if all propagate
    wire [3:0] p1 = a[7:4] ^ b[7:4];
    wire blkp1 = &p1;                  // block propagate
    wire rcout1;
    add_rc4_unit u1(.a(a[7:4]),.b(b[7:4]),.cin(c[1]),.sum(sum[7:4]),.cout(rcout1));
    assign c[2] = blkp1 ? c[1] : rcout1;   // skip carry if all propagate
    wire [3:0] p2 = a[11:8] ^ b[11:8];
    wire blkp2 = &p2;                  // block propagate
    wire rcout2;
    add_rc4_unit u2(.a(a[11:8]),.b(b[11:8]),.cin(c[2]),.sum(sum[11:8]),.cout(rcout2));
    assign c[3] = blkp2 ? c[2] : rcout2;   // skip carry if all propagate
    wire [3:0] p3 = a[15:12] ^ b[15:12];
    wire blkp3 = &p3;                  // block propagate
    wire rcout3;
    add_rc4_unit u3(.a(a[15:12]),.b(b[15:12]),.cin(c[3]),.sum(sum[15:12]),.cout(rcout3));
    assign c[4] = blkp3 ? c[3] : rcout3;   // skip carry if all propagate
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


