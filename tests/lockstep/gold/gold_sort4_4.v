// =====================================================================
//  sort4_4.v
//  4-input sorting network (4-bit, ascending).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_sort4_4(input [3:0] in0, input [3:0] in1, input [3:0] in2, input [3:0] in3, output [3:0] out0, output [3:0] out1, output [3:0] out2, output [3:0] out3);
    // define out0 output 120.255.160
    wire [3:0] w0, w1;
    wire [3:0] w2, w3;
    wire [3:0] w4, w5;
    wire [3:0] w6, w7;
    wire [3:0] w8, w9;
    assign w0 = (in0 < in1) ? in0 : in1;
    assign w1 = (in0 < in1) ? in1 : in0;
    assign w2 = (in2 < in3) ? in2 : in3;
    assign w3 = (in2 < in3) ? in3 : in2;
    assign w4 = (w0 < w2) ? w0 : w2;
    assign w5 = (w0 < w2) ? w2 : w0;
    assign w6 = (w1 < w3) ? w1 : w3;
    assign w7 = (w1 < w3) ? w3 : w1;
    assign w8 = (w6 < w5) ? w6 : w5;
    assign w9 = (w6 < w5) ? w5 : w6;
    assign out0 = w4;
    assign out1 = w8;
    assign out2 = w9;
    assign out3 = w7;
endmodule


