// =====================================================================
//  bitonic_sort4_8.v
//  4-input bitonic sorting network (8-bit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_bitonic_sort4_8(input [7:0] in0, input [7:0] in1, input [7:0] in2, input [7:0] in3, output [7:0] out0, output [7:0] out1, output [7:0] out2, output [7:0] out3);
    // define out0 output 120.255.160
    wire [7:0] b0, b1;
    wire [7:0] b2, b3;
    wire [7:0] b4, b5;
    wire [7:0] b6, b7;
    wire [7:0] b8, b9;
    wire [7:0] b10, b11;
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
    assign out0 = b8;
    assign out1 = b9;
    assign out2 = b10;
    assign out3 = b11;
endmodule


