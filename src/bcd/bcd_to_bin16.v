// =====================================================================
//  bcd_to_bin16.v
//  5-digit BCD -> 16-bit binary.
//  Structural digit*10^i shift-add; no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_to_bin16(input [19:0] bcd, output [15:0] a);
    // define bcd input 80.160.255   // define a output 120.255.160
    wire [19:0] t0_0 = ({16'b0, bcd[3:0]}) << 0;
    wire [19:0] t1_1 = ({16'b0, bcd[7:4]}) << 1;
    wire [19:0] t1_3 = ({16'b0, bcd[7:4]}) << 3;
    wire [19:0] t2_2 = ({16'b0, bcd[11:8]}) << 2;
    wire [19:0] t2_5 = ({16'b0, bcd[11:8]}) << 5;
    wire [19:0] t2_6 = ({16'b0, bcd[11:8]}) << 6;
    wire [19:0] t3_3 = ({16'b0, bcd[15:12]}) << 3;
    wire [19:0] t3_5 = ({16'b0, bcd[15:12]}) << 5;
    wire [19:0] t3_6 = ({16'b0, bcd[15:12]}) << 6;
    wire [19:0] t3_7 = ({16'b0, bcd[15:12]}) << 7;
    wire [19:0] t3_8 = ({16'b0, bcd[15:12]}) << 8;
    wire [19:0] t3_9 = ({16'b0, bcd[15:12]}) << 9;
    wire [19:0] t4_4 = ({16'b0, bcd[19:16]}) << 4;
    wire [19:0] t4_8 = ({16'b0, bcd[19:16]}) << 8;
    wire [19:0] t4_9 = ({16'b0, bcd[19:16]}) << 9;
    wire [19:0] t4_10 = ({16'b0, bcd[19:16]}) << 10;
    wire [19:0] t4_13 = ({16'b0, bcd[19:16]}) << 13;
    wire [19:0] acc0; wire c0;
    bcdadd20 ad0(.a(t0_0),.b(t1_1),.cin(1'b0),.sum(acc0),.cout(c0));
    wire [19:0] acc1; wire c1;
    bcdadd20 ad1(.a(acc0),.b(t1_3),.cin(1'b0),.sum(acc1),.cout(c1));
    wire [19:0] acc2; wire c2;
    bcdadd20 ad2(.a(acc1),.b(t2_2),.cin(1'b0),.sum(acc2),.cout(c2));
    wire [19:0] acc3; wire c3;
    bcdadd20 ad3(.a(acc2),.b(t2_5),.cin(1'b0),.sum(acc3),.cout(c3));
    wire [19:0] acc4; wire c4;
    bcdadd20 ad4(.a(acc3),.b(t2_6),.cin(1'b0),.sum(acc4),.cout(c4));
    wire [19:0] acc5; wire c5;
    bcdadd20 ad5(.a(acc4),.b(t3_3),.cin(1'b0),.sum(acc5),.cout(c5));
    wire [19:0] acc6; wire c6;
    bcdadd20 ad6(.a(acc5),.b(t3_5),.cin(1'b0),.sum(acc6),.cout(c6));
    wire [19:0] acc7; wire c7;
    bcdadd20 ad7(.a(acc6),.b(t3_6),.cin(1'b0),.sum(acc7),.cout(c7));
    wire [19:0] acc8; wire c8;
    bcdadd20 ad8(.a(acc7),.b(t3_7),.cin(1'b0),.sum(acc8),.cout(c8));
    wire [19:0] acc9; wire c9;
    bcdadd20 ad9(.a(acc8),.b(t3_8),.cin(1'b0),.sum(acc9),.cout(c9));
    wire [19:0] acc10; wire c10;
    bcdadd20 ad10(.a(acc9),.b(t3_9),.cin(1'b0),.sum(acc10),.cout(c10));
    wire [19:0] acc11; wire c11;
    bcdadd20 ad11(.a(acc10),.b(t4_4),.cin(1'b0),.sum(acc11),.cout(c11));
    wire [19:0] acc12; wire c12;
    bcdadd20 ad12(.a(acc11),.b(t4_8),.cin(1'b0),.sum(acc12),.cout(c12));
    wire [19:0] acc13; wire c13;
    bcdadd20 ad13(.a(acc12),.b(t4_9),.cin(1'b0),.sum(acc13),.cout(c13));
    wire [19:0] acc14; wire c14;
    bcdadd20 ad14(.a(acc13),.b(t4_10),.cin(1'b0),.sum(acc14),.cout(c14));
    wire [19:0] acc15; wire c15;
    bcdadd20 ad15(.a(acc14),.b(t4_13),.cin(1'b0),.sum(acc15),.cout(c15));
    assign a = acc15[15:0];
endmodule

module bcdadd20(input [19:0] a, input [19:0] b, input cin, output [19:0] sum, output cout);
    wire [20:0] c; assign c[0]=cin;
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
    full_adder fa12(.a(a[12]),.b(b[12]),.cin(c[12]),.sum(sum[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(b[13]),.cin(c[13]),.sum(sum[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(b[14]),.cin(c[14]),.sum(sum[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(b[15]),.cin(c[15]),.sum(sum[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(b[16]),.cin(c[16]),.sum(sum[16]),.cout(c[17]));
    full_adder fa17(.a(a[17]),.b(b[17]),.cin(c[17]),.sum(sum[17]),.cout(c[18]));
    full_adder fa18(.a(a[18]),.b(b[18]),.cin(c[18]),.sum(sum[18]),.cout(c[19]));
    full_adder fa19(.a(a[19]),.b(b[19]),.cin(c[19]),.sum(sum[19]),.cout(c[20]));
    assign cout=c[20];
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


