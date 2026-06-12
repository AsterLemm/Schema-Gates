// =====================================================================
//  sort8_4.v
//  8-input sorting network (4-bit, ascending).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_sort8_4(input [3:0] in0, input [3:0] in1, input [3:0] in2, input [3:0] in3, input [3:0] in4, input [3:0] in5, input [3:0] in6, input [3:0] in7, output [3:0] out0, output [3:0] out1, output [3:0] out2, output [3:0] out3, output [3:0] out4, output [3:0] out5, output [3:0] out6, output [3:0] out7);
    // define out0 output 120.255.160
    wire [3:0] w0, w1;
    wire [3:0] w2, w3;
    wire [3:0] w4, w5;
    wire [3:0] w6, w7;
    wire [3:0] w8, w9;
    wire [3:0] w10, w11;
    wire [3:0] w12, w13;
    wire [3:0] w14, w15;
    wire [3:0] w16, w17;
    wire [3:0] w18, w19;
    wire [3:0] w20, w21;
    wire [3:0] w22, w23;
    wire [3:0] w24, w25;
    wire [3:0] w26, w27;
    wire [3:0] w28, w29;
    wire [3:0] w30, w31;
    wire [3:0] w32, w33;
    wire [3:0] w34, w35;
    wire [3:0] w36, w37;
    assign w0 = (in0 < in1) ? in0 : in1;
    assign w1 = (in0 < in1) ? in1 : in0;
    assign w2 = (in2 < in3) ? in2 : in3;
    assign w3 = (in2 < in3) ? in3 : in2;
    assign w4 = (in4 < in5) ? in4 : in5;
    assign w5 = (in4 < in5) ? in5 : in4;
    assign w6 = (in6 < in7) ? in6 : in7;
    assign w7 = (in6 < in7) ? in7 : in6;
    assign w8 = (w0 < w2) ? w0 : w2;
    assign w9 = (w0 < w2) ? w2 : w0;
    assign w10 = (w1 < w3) ? w1 : w3;
    assign w11 = (w1 < w3) ? w3 : w1;
    assign w12 = (w4 < w6) ? w4 : w6;
    assign w13 = (w4 < w6) ? w6 : w4;
    assign w14 = (w5 < w7) ? w5 : w7;
    assign w15 = (w5 < w7) ? w7 : w5;
    assign w16 = (w10 < w9) ? w10 : w9;
    assign w17 = (w10 < w9) ? w9 : w10;
    assign w18 = (w14 < w13) ? w14 : w13;
    assign w19 = (w14 < w13) ? w13 : w14;
    assign w20 = (w8 < w12) ? w8 : w12;
    assign w21 = (w8 < w12) ? w12 : w8;
    assign w22 = (w11 < w15) ? w11 : w15;
    assign w23 = (w11 < w15) ? w15 : w11;
    assign w24 = (w16 < w18) ? w16 : w18;
    assign w25 = (w16 < w18) ? w18 : w16;
    assign w26 = (w17 < w19) ? w17 : w19;
    assign w27 = (w17 < w19) ? w19 : w17;
    assign w28 = (w24 < w21) ? w24 : w21;
    assign w29 = (w24 < w21) ? w21 : w24;
    assign w30 = (w22 < w27) ? w22 : w27;
    assign w31 = (w22 < w27) ? w27 : w22;
    assign w32 = (w26 < w29) ? w26 : w29;
    assign w33 = (w26 < w29) ? w29 : w26;
    assign w34 = (w30 < w25) ? w30 : w25;
    assign w35 = (w30 < w25) ? w25 : w30;
    assign w36 = (w34 < w33) ? w34 : w33;
    assign w37 = (w34 < w33) ? w33 : w34;
    assign out0 = w20;
    assign out1 = w28;
    assign out2 = w32;
    assign out3 = w36;
    assign out4 = w37;
    assign out5 = w35;
    assign out6 = w31;
    assign out7 = w23;
endmodule


