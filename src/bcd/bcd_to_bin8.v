// =====================================================================
//  bcd_to_bin8.v
//  3-digit BCD -> 8-bit binary.
//  Structural digit*10^i shift-add; no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_to_bin8(input [11:0] bcd, output [7:0] a);
    // define bcd input 80.160.255   // define a output 120.255.160
    wire [11:0] t0_0 = ({8'b0, bcd[3:0]}) << 0;
    wire [11:0] t1_1 = ({8'b0, bcd[7:4]}) << 1;
    wire [11:0] t1_3 = ({8'b0, bcd[7:4]}) << 3;
    wire [11:0] t2_2 = ({8'b0, bcd[11:8]}) << 2;
    wire [11:0] t2_5 = ({8'b0, bcd[11:8]}) << 5;
    wire [11:0] t2_6 = ({8'b0, bcd[11:8]}) << 6;
    wire [11:0] acc0; wire c0;
    bcdadd12 ad0(.a(t0_0),.b(t1_1),.cin(1'b0),.sum(acc0),.cout(c0));
    wire [11:0] acc1; wire c1;
    bcdadd12 ad1(.a(acc0),.b(t1_3),.cin(1'b0),.sum(acc1),.cout(c1));
    wire [11:0] acc2; wire c2;
    bcdadd12 ad2(.a(acc1),.b(t2_2),.cin(1'b0),.sum(acc2),.cout(c2));
    wire [11:0] acc3; wire c3;
    bcdadd12 ad3(.a(acc2),.b(t2_5),.cin(1'b0),.sum(acc3),.cout(c3));
    wire [11:0] acc4; wire c4;
    bcdadd12 ad4(.a(acc3),.b(t2_6),.cin(1'b0),.sum(acc4),.cout(c4));
    assign a = acc4[7:0];
endmodule

module bcdadd12(input [11:0] a, input [11:0] b, input cin, output [11:0] sum, output cout);
    wire [12:0] c; assign c[0]=cin;
    full_adder fa0(.a(a[0]),.b(b[0]),.cin(c[0]),.sum(sum[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(b[1]),.cin(c[1]),.sum(sum[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(b[2]),.cin(c[2]),.sum(sum[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(b[3]),.cin(c[3]),.sum(sum[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(b[4]),.cin(c[4]),.sum(sum[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(b[5]),.cin(c[5]),.sum(sum[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(b[6]),.cin(c[6]),.sum(sum[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(b[7]),.cin(c[7]),.sum(sum[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(b[8]),.cin(c[8]),.sum(sum[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(b[9]),.cin(c[9]),.sum(sum[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(b[10]),.cin(c[10]),.sum(sum[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(b[11]),.cin(c[11]),.sum(sum[11]),.cout(c[12]));
    assign cout=c[12];
endmodule

module half_adder(input a, input b, output sum, output carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule

module full_adder(input a, input b, input cin, output sum, output cout);
    wire s0, c0, c1;
    half_adder ha0(.a(a),  .b(b),   .sum(s0),  .carry(c0));
    half_adder ha1(.a(s0), .b(cin), .sum(sum), .carry(c1));
    assign cout = c0 | c1;
endmodule


