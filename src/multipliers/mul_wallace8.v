// =====================================================================
//  mul_wallace8.v
//  8x8 Wallace-tree multiplier (3:2 compressor reduction, final CPA).
//  Structural compressor tree of full adders; no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mul_wallace8(input [7:0] a, input [7:0] b, output [15:0] product);
    // define a input 80.160.255
    // define b input 80.200.255
    // define product output 120.255.160
    wire pp0_0 = a[0] & b[0];
    wire pp0_1 = a[1] & b[0];
    wire pp0_2 = a[2] & b[0];
    wire pp0_3 = a[3] & b[0];
    wire pp0_4 = a[4] & b[0];
    wire pp0_5 = a[5] & b[0];
    wire pp0_6 = a[6] & b[0];
    wire pp0_7 = a[7] & b[0];
    wire pp1_0 = a[0] & b[1];
    wire pp1_1 = a[1] & b[1];
    wire pp1_2 = a[2] & b[1];
    wire pp1_3 = a[3] & b[1];
    wire pp1_4 = a[4] & b[1];
    wire pp1_5 = a[5] & b[1];
    wire pp1_6 = a[6] & b[1];
    wire pp1_7 = a[7] & b[1];
    wire pp2_0 = a[0] & b[2];
    wire pp2_1 = a[1] & b[2];
    wire pp2_2 = a[2] & b[2];
    wire pp2_3 = a[3] & b[2];
    wire pp2_4 = a[4] & b[2];
    wire pp2_5 = a[5] & b[2];
    wire pp2_6 = a[6] & b[2];
    wire pp2_7 = a[7] & b[2];
    wire pp3_0 = a[0] & b[3];
    wire pp3_1 = a[1] & b[3];
    wire pp3_2 = a[2] & b[3];
    wire pp3_3 = a[3] & b[3];
    wire pp3_4 = a[4] & b[3];
    wire pp3_5 = a[5] & b[3];
    wire pp3_6 = a[6] & b[3];
    wire pp3_7 = a[7] & b[3];
    wire pp4_0 = a[0] & b[4];
    wire pp4_1 = a[1] & b[4];
    wire pp4_2 = a[2] & b[4];
    wire pp4_3 = a[3] & b[4];
    wire pp4_4 = a[4] & b[4];
    wire pp4_5 = a[5] & b[4];
    wire pp4_6 = a[6] & b[4];
    wire pp4_7 = a[7] & b[4];
    wire pp5_0 = a[0] & b[5];
    wire pp5_1 = a[1] & b[5];
    wire pp5_2 = a[2] & b[5];
    wire pp5_3 = a[3] & b[5];
    wire pp5_4 = a[4] & b[5];
    wire pp5_5 = a[5] & b[5];
    wire pp5_6 = a[6] & b[5];
    wire pp5_7 = a[7] & b[5];
    wire pp6_0 = a[0] & b[6];
    wire pp6_1 = a[1] & b[6];
    wire pp6_2 = a[2] & b[6];
    wire pp6_3 = a[3] & b[6];
    wire pp6_4 = a[4] & b[6];
    wire pp6_5 = a[5] & b[6];
    wire pp6_6 = a[6] & b[6];
    wire pp6_7 = a[7] & b[6];
    wire pp7_0 = a[0] & b[7];
    wire pp7_1 = a[1] & b[7];
    wire pp7_2 = a[2] & b[7];
    wire pp7_3 = a[3] & b[7];
    wire pp7_4 = a[4] & b[7];
    wire pp7_5 = a[5] & b[7];
    wire pp7_6 = a[6] & b[7];
    wire pp7_7 = a[7] & b[7];
    wire w1, w2;
    full_adder fc2(.a(pp0_2),.b(pp1_1),.cin(pp2_0),.sum(w1),.cout(w2));
    wire w3, w4;
    full_adder fc4(.a(pp0_3),.b(pp1_2),.cin(pp2_1),.sum(w3),.cout(w4));
    wire w5, w6;
    full_adder fc6(.a(pp3_0),.b(w2),.cin(w3),.sum(w5),.cout(w6));
    wire w7, w8;
    full_adder fc8(.a(pp0_4),.b(pp1_3),.cin(pp2_2),.sum(w7),.cout(w8));
    wire w9, w10;
    full_adder fc10(.a(pp3_1),.b(pp4_0),.cin(w4),.sum(w9),.cout(w10));
    wire w11, w12;
    full_adder fc12(.a(w6),.b(w7),.cin(w9),.sum(w11),.cout(w12));
    wire w13, w14;
    full_adder fc14(.a(pp0_5),.b(pp1_4),.cin(pp2_3),.sum(w13),.cout(w14));
    wire w15, w16;
    full_adder fc16(.a(pp3_2),.b(pp4_1),.cin(pp5_0),.sum(w15),.cout(w16));
    wire w17, w18;
    full_adder fc18(.a(w8),.b(w10),.cin(w12),.sum(w17),.cout(w18));
    wire w19, w20;
    full_adder fc20(.a(w13),.b(w15),.cin(w17),.sum(w19),.cout(w20));
    wire w21, w22;
    full_adder fc22(.a(pp0_6),.b(pp1_5),.cin(pp2_4),.sum(w21),.cout(w22));
    wire w23, w24;
    full_adder fc24(.a(pp3_3),.b(pp4_2),.cin(pp5_1),.sum(w23),.cout(w24));
    wire w25, w26;
    full_adder fc26(.a(pp6_0),.b(w14),.cin(w16),.sum(w25),.cout(w26));
    wire w27, w28;
    full_adder fc28(.a(w18),.b(w20),.cin(w21),.sum(w27),.cout(w28));
    wire w29, w30;
    full_adder fc30(.a(w23),.b(w25),.cin(w27),.sum(w29),.cout(w30));
    wire w31, w32;
    full_adder fc32(.a(pp0_7),.b(pp1_6),.cin(pp2_5),.sum(w31),.cout(w32));
    wire w33, w34;
    full_adder fc34(.a(pp3_4),.b(pp4_3),.cin(pp5_2),.sum(w33),.cout(w34));
    wire w35, w36;
    full_adder fc36(.a(pp6_1),.b(pp7_0),.cin(w22),.sum(w35),.cout(w36));
    wire w37, w38;
    full_adder fc38(.a(w24),.b(w26),.cin(w28),.sum(w37),.cout(w38));
    wire w39, w40;
    full_adder fc40(.a(w30),.b(w31),.cin(w33),.sum(w39),.cout(w40));
    wire w41, w42;
    full_adder fc42(.a(w35),.b(w37),.cin(w39),.sum(w41),.cout(w42));
    wire w43, w44;
    full_adder fc44(.a(pp1_7),.b(pp2_6),.cin(pp3_5),.sum(w43),.cout(w44));
    wire w45, w46;
    full_adder fc46(.a(pp4_4),.b(pp5_3),.cin(pp6_2),.sum(w45),.cout(w46));
    wire w47, w48;
    full_adder fc48(.a(pp7_1),.b(w32),.cin(w34),.sum(w47),.cout(w48));
    wire w49, w50;
    full_adder fc50(.a(w36),.b(w38),.cin(w40),.sum(w49),.cout(w50));
    wire w51, w52;
    full_adder fc52(.a(w42),.b(w43),.cin(w45),.sum(w51),.cout(w52));
    wire w53, w54;
    full_adder fc54(.a(w47),.b(w49),.cin(w51),.sum(w53),.cout(w54));
    wire w55, w56;
    full_adder fc56(.a(pp2_7),.b(pp3_6),.cin(pp4_5),.sum(w55),.cout(w56));
    wire w57, w58;
    full_adder fc58(.a(pp5_4),.b(pp6_3),.cin(pp7_2),.sum(w57),.cout(w58));
    wire w59, w60;
    full_adder fc60(.a(w44),.b(w46),.cin(w48),.sum(w59),.cout(w60));
    wire w61, w62;
    full_adder fc62(.a(w50),.b(w52),.cin(w54),.sum(w61),.cout(w62));
    wire w63, w64;
    full_adder fc64(.a(w55),.b(w57),.cin(w59),.sum(w63),.cout(w64));
    wire w65, w66;
    full_adder fc66(.a(pp3_7),.b(pp4_6),.cin(pp5_5),.sum(w65),.cout(w66));
    wire w67, w68;
    full_adder fc68(.a(pp6_4),.b(pp7_3),.cin(w56),.sum(w67),.cout(w68));
    wire w69, w70;
    full_adder fc70(.a(w58),.b(w60),.cin(w62),.sum(w69),.cout(w70));
    wire w71, w72;
    full_adder fc72(.a(w64),.b(w65),.cin(w67),.sum(w71),.cout(w72));
    wire w73, w74;
    full_adder fc74(.a(pp4_7),.b(pp5_6),.cin(pp6_5),.sum(w73),.cout(w74));
    wire w75, w76;
    full_adder fc76(.a(pp7_4),.b(w66),.cin(w68),.sum(w75),.cout(w76));
    wire w77, w78;
    full_adder fc78(.a(w70),.b(w72),.cin(w73),.sum(w77),.cout(w78));
    wire w79, w80;
    full_adder fc80(.a(pp5_7),.b(pp6_6),.cin(pp7_5),.sum(w79),.cout(w80));
    wire w81, w82;
    full_adder fc82(.a(w74),.b(w76),.cin(w78),.sum(w81),.cout(w82));
    wire w83, w84;
    full_adder fc84(.a(pp6_7),.b(pp7_6),.cin(w80),.sum(w83),.cout(w84));
    wire [15:0] opA = {1'b0, pp7_7, w82, w79, w75, w69, w61, w53, w41, w29, w19, w11, w5, w1, pp0_1, pp0_0};
    wire [15:0] opB = {1'b0, w84, w83, w81, w77, w71, w63, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, pp1_0, 1'b0};
    wire co_f;
    rca16 final_add(.a(opA),.b(opB),.cin(1'b0),.sum(product),.cout(co_f));
endmodule

module rca16(input [15:0] a, input [15:0] b, input cin, output [15:0] sum, output cout);
    wire [16:0] c; assign c[0]=cin;
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
    assign cout=c[16];
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


