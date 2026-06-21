// =====================================================================
//  fp16_div.v
//  fp16 divider (structural 22/11 restoring mantissa divide); no / operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp16_div(input [15:0] a, input [15:0] b, output reg [15:0] y);
    // define a input 80.160.255
    // define b input 80.200.255
    // define y output 120.255.160
    wire sa=a[15], sb=b[15];
    wire [4:0] ea=a[14:10], eb=b[14:10];
    wire [10:0] ma={|ea,a[9:0]}, mb={|eb,b[9:0]};
    // structural mantissa divide: (ma<<11) / mb, 22-bit dividend / 11-bit divisor
    wire [21:0] dividend = {ma, 11'b0};
    wire [21:0] q_raw; wire [10:0] rem_unused;
    fp16m_div dv(.dividend(dividend), .divisor(mb), .quotient(q_raw), .remainder(rem_unused));
    reg [21:0] q; reg signed [6:0] exp_res;
    always @(*) begin
        if (eb==0) y={sa^sb,5'b11111,10'b0};       // div by zero -> inf
        else if (ea==0) y={sa^sb,15'b0};
        else begin
            q = q_raw; exp_res = ea - eb + 15;
            if (!q[11]) begin q=q<<1; exp_res=exp_res-1; end
            if (exp_res<=0) y={sa^sb,15'b0};
            else if (exp_res>=31) y={sa^sb,5'b11111,10'b0};
            else y={sa^sb, exp_res[4:0], q[10:1]};
        end
    end
endmodule

module fp16m_div(input [21:0] dividend, input [10:0] divisor,
    output [21:0] quotient, output [10:0] remainder);
    wire [11:0] rem0 = {12{1'b0}};
    wire [11:0] sh0 = {rem0[10:0], dividend[21]};
    wire [11:0] tr0; wire bo0;
    fpsub12_0 su0(.a(sh0), .b({1'b0,divisor}), .diff(tr0), .bout(bo0));
    wire q0 = ~bo0;
    wire [11:0] rem1 = q0 ? tr0 : sh0;
    wire [11:0] sh1 = {rem1[10:0], dividend[20]};
    wire [11:0] tr1; wire bo1;
    fpsub12_1 su1(.a(sh1), .b({1'b0,divisor}), .diff(tr1), .bout(bo1));
    wire q1 = ~bo1;
    wire [11:0] rem2 = q1 ? tr1 : sh1;
    wire [11:0] sh2 = {rem2[10:0], dividend[19]};
    wire [11:0] tr2; wire bo2;
    fpsub12_2 su2(.a(sh2), .b({1'b0,divisor}), .diff(tr2), .bout(bo2));
    wire q2 = ~bo2;
    wire [11:0] rem3 = q2 ? tr2 : sh2;
    wire [11:0] sh3 = {rem3[10:0], dividend[18]};
    wire [11:0] tr3; wire bo3;
    fpsub12_3 su3(.a(sh3), .b({1'b0,divisor}), .diff(tr3), .bout(bo3));
    wire q3 = ~bo3;
    wire [11:0] rem4 = q3 ? tr3 : sh3;
    wire [11:0] sh4 = {rem4[10:0], dividend[17]};
    wire [11:0] tr4; wire bo4;
    fpsub12_4 su4(.a(sh4), .b({1'b0,divisor}), .diff(tr4), .bout(bo4));
    wire q4 = ~bo4;
    wire [11:0] rem5 = q4 ? tr4 : sh4;
    wire [11:0] sh5 = {rem5[10:0], dividend[16]};
    wire [11:0] tr5; wire bo5;
    fpsub12_5 su5(.a(sh5), .b({1'b0,divisor}), .diff(tr5), .bout(bo5));
    wire q5 = ~bo5;
    wire [11:0] rem6 = q5 ? tr5 : sh5;
    wire [11:0] sh6 = {rem6[10:0], dividend[15]};
    wire [11:0] tr6; wire bo6;
    fpsub12_6 su6(.a(sh6), .b({1'b0,divisor}), .diff(tr6), .bout(bo6));
    wire q6 = ~bo6;
    wire [11:0] rem7 = q6 ? tr6 : sh6;
    wire [11:0] sh7 = {rem7[10:0], dividend[14]};
    wire [11:0] tr7; wire bo7;
    fpsub12_7 su7(.a(sh7), .b({1'b0,divisor}), .diff(tr7), .bout(bo7));
    wire q7 = ~bo7;
    wire [11:0] rem8 = q7 ? tr7 : sh7;
    wire [11:0] sh8 = {rem8[10:0], dividend[13]};
    wire [11:0] tr8; wire bo8;
    fpsub12_8 su8(.a(sh8), .b({1'b0,divisor}), .diff(tr8), .bout(bo8));
    wire q8 = ~bo8;
    wire [11:0] rem9 = q8 ? tr8 : sh8;
    wire [11:0] sh9 = {rem9[10:0], dividend[12]};
    wire [11:0] tr9; wire bo9;
    fpsub12_9 su9(.a(sh9), .b({1'b0,divisor}), .diff(tr9), .bout(bo9));
    wire q9 = ~bo9;
    wire [11:0] rem10 = q9 ? tr9 : sh9;
    wire [11:0] sh10 = {rem10[10:0], dividend[11]};
    wire [11:0] tr10; wire bo10;
    fpsub12_10 su10(.a(sh10), .b({1'b0,divisor}), .diff(tr10), .bout(bo10));
    wire q10 = ~bo10;
    wire [11:0] rem11 = q10 ? tr10 : sh10;
    wire [11:0] sh11 = {rem11[10:0], dividend[10]};
    wire [11:0] tr11; wire bo11;
    fpsub12_11 su11(.a(sh11), .b({1'b0,divisor}), .diff(tr11), .bout(bo11));
    wire q11 = ~bo11;
    wire [11:0] rem12 = q11 ? tr11 : sh11;
    wire [11:0] sh12 = {rem12[10:0], dividend[9]};
    wire [11:0] tr12; wire bo12;
    fpsub12_12 su12(.a(sh12), .b({1'b0,divisor}), .diff(tr12), .bout(bo12));
    wire q12 = ~bo12;
    wire [11:0] rem13 = q12 ? tr12 : sh12;
    wire [11:0] sh13 = {rem13[10:0], dividend[8]};
    wire [11:0] tr13; wire bo13;
    fpsub12_13 su13(.a(sh13), .b({1'b0,divisor}), .diff(tr13), .bout(bo13));
    wire q13 = ~bo13;
    wire [11:0] rem14 = q13 ? tr13 : sh13;
    wire [11:0] sh14 = {rem14[10:0], dividend[7]};
    wire [11:0] tr14; wire bo14;
    fpsub12_14 su14(.a(sh14), .b({1'b0,divisor}), .diff(tr14), .bout(bo14));
    wire q14 = ~bo14;
    wire [11:0] rem15 = q14 ? tr14 : sh14;
    wire [11:0] sh15 = {rem15[10:0], dividend[6]};
    wire [11:0] tr15; wire bo15;
    fpsub12_15 su15(.a(sh15), .b({1'b0,divisor}), .diff(tr15), .bout(bo15));
    wire q15 = ~bo15;
    wire [11:0] rem16 = q15 ? tr15 : sh15;
    wire [11:0] sh16 = {rem16[10:0], dividend[5]};
    wire [11:0] tr16; wire bo16;
    fpsub12_16 su16(.a(sh16), .b({1'b0,divisor}), .diff(tr16), .bout(bo16));
    wire q16 = ~bo16;
    wire [11:0] rem17 = q16 ? tr16 : sh16;
    wire [11:0] sh17 = {rem17[10:0], dividend[4]};
    wire [11:0] tr17; wire bo17;
    fpsub12_17 su17(.a(sh17), .b({1'b0,divisor}), .diff(tr17), .bout(bo17));
    wire q17 = ~bo17;
    wire [11:0] rem18 = q17 ? tr17 : sh17;
    wire [11:0] sh18 = {rem18[10:0], dividend[3]};
    wire [11:0] tr18; wire bo18;
    fpsub12_18 su18(.a(sh18), .b({1'b0,divisor}), .diff(tr18), .bout(bo18));
    wire q18 = ~bo18;
    wire [11:0] rem19 = q18 ? tr18 : sh18;
    wire [11:0] sh19 = {rem19[10:0], dividend[2]};
    wire [11:0] tr19; wire bo19;
    fpsub12_19 su19(.a(sh19), .b({1'b0,divisor}), .diff(tr19), .bout(bo19));
    wire q19 = ~bo19;
    wire [11:0] rem20 = q19 ? tr19 : sh19;
    wire [11:0] sh20 = {rem20[10:0], dividend[1]};
    wire [11:0] tr20; wire bo20;
    fpsub12_20 su20(.a(sh20), .b({1'b0,divisor}), .diff(tr20), .bout(bo20));
    wire q20 = ~bo20;
    wire [11:0] rem21 = q20 ? tr20 : sh20;
    wire [11:0] sh21 = {rem21[10:0], dividend[0]};
    wire [11:0] tr21; wire bo21;
    fpsub12_21 su21(.a(sh21), .b({1'b0,divisor}), .diff(tr21), .bout(bo21));
    wire q21 = ~bo21;
    wire [11:0] rem22 = q21 ? tr21 : sh21;
    assign quotient  = {q0, q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15, q16, q17, q18, q19, q20, q21};
    assign remainder = rem22[10:0];
endmodule

module fpsub12_0(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_1(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_2(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_3(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_4(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_5(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_6(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_7(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_8(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_9(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_10(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_11(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_12(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_13(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_14(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_15(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_16(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_17(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_18(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_19(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_20(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
endmodule

module fpsub12_21(input [11:0] a, input [11:0] b, output [11:0] diff, output bout);
    wire [12:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    assign bout = ~c[12];
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


