// =====================================================================
//  bitonic_sort8_8.v
//  8-input bitonic sorting network (8-bit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_bitonic_sort8_8(input [7:0] in0, input [7:0] in1, input [7:0] in2, input [7:0] in3, input [7:0] in4, input [7:0] in5, input [7:0] in6, input [7:0] in7, output [7:0] out0, output [7:0] out1, output [7:0] out2, output [7:0] out3, output [7:0] out4, output [7:0] out5, output [7:0] out6, output [7:0] out7);
    // define out0 output 120.255.160
    wire [7:0] b0, b1;
    wire [7:0] b2, b3;
    wire [7:0] b4, b5;
    wire [7:0] b6, b7;
    wire [7:0] b8, b9;
    wire [7:0] b10, b11;
    wire [7:0] b12, b13;
    wire [7:0] b14, b15;
    wire [7:0] b16, b17;
    wire [7:0] b18, b19;
    wire [7:0] b20, b21;
    wire [7:0] b22, b23;
    wire [7:0] b24, b25;
    wire [7:0] b26, b27;
    wire [7:0] b28, b29;
    wire [7:0] b30, b31;
    wire [7:0] b32, b33;
    wire [7:0] b34, b35;
    wire [7:0] b36, b37;
    wire [7:0] b38, b39;
    wire [7:0] b40, b41;
    wire [7:0] b42, b43;
    wire [7:0] b44, b45;
    wire [7:0] b46, b47;
    assign b0 = (in0 < in1) ? in0 : in1;
    assign b1 = (in0 < in1) ? in1 : in0;
    assign b2 = (in2 > in3) ? in2 : in3;
    assign b3 = (in2 > in3) ? in3 : in2;
    assign b4 = (b0 < b2) ? b0 : b2;
    assign b5 = (b0 < b2) ? b2 : b0;
    assign b6 = (b1 < b3) ? b1 : b3;
    assign b7 = (b1 < b3) ? b3 : b1;
    assign b8 = (b4 < b6) ? b4 : b6;
    assign b9 = (b4 < b6) ? b6 : b4;
    assign b10 = (b5 < b7) ? b5 : b7;
    assign b11 = (b5 < b7) ? b7 : b5;
    assign b12 = (in4 < in5) ? in4 : in5;
    assign b13 = (in4 < in5) ? in5 : in4;
    assign b14 = (in6 > in7) ? in6 : in7;
    assign b15 = (in6 > in7) ? in7 : in6;
    assign b16 = (b12 > b14) ? b12 : b14;
    assign b17 = (b12 > b14) ? b14 : b12;
    assign b18 = (b13 > b15) ? b13 : b15;
    assign b19 = (b13 > b15) ? b15 : b13;
    assign b20 = (b16 > b18) ? b16 : b18;
    assign b21 = (b16 > b18) ? b18 : b16;
    assign b22 = (b17 > b19) ? b17 : b19;
    assign b23 = (b17 > b19) ? b19 : b17;
    assign b24 = (b8 < b20) ? b8 : b20;
    assign b25 = (b8 < b20) ? b20 : b8;
    assign b26 = (b9 < b21) ? b9 : b21;
    assign b27 = (b9 < b21) ? b21 : b9;
    assign b28 = (b10 < b22) ? b10 : b22;
    assign b29 = (b10 < b22) ? b22 : b10;
    assign b30 = (b11 < b23) ? b11 : b23;
    assign b31 = (b11 < b23) ? b23 : b11;
    assign b32 = (b24 < b28) ? b24 : b28;
    assign b33 = (b24 < b28) ? b28 : b24;
    assign b34 = (b26 < b30) ? b26 : b30;
    assign b35 = (b26 < b30) ? b30 : b26;
    assign b36 = (b32 < b34) ? b32 : b34;
    assign b37 = (b32 < b34) ? b34 : b32;
    assign b38 = (b33 < b35) ? b33 : b35;
    assign b39 = (b33 < b35) ? b35 : b33;
    assign b40 = (b25 < b29) ? b25 : b29;
    assign b41 = (b25 < b29) ? b29 : b25;
    assign b42 = (b27 < b31) ? b27 : b31;
    assign b43 = (b27 < b31) ? b31 : b27;
    assign b44 = (b40 < b42) ? b40 : b42;
    assign b45 = (b40 < b42) ? b42 : b40;
    assign b46 = (b41 < b43) ? b41 : b43;
    assign b47 = (b41 < b43) ? b43 : b41;
    assign out0 = b36;
    assign out1 = b37;
    assign out2 = b38;
    assign out3 = b39;
    assign out4 = b44;
    assign out5 = b45;
    assign out6 = b46;
    assign out7 = b47;
endmodule


