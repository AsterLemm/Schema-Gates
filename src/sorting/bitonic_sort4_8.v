// =====================================================================
//  bitonic_sort4_8.v
//  4-input bitonic sorting network (8-bit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- bitonic_sort4_8_cmpasc : ascending compare-exchange (o1 = min, o2 = max) ---
module bitonic_sort4_8_cmpasc(input [7:0] x, input [7:0] y, output [7:0] o1, output [7:0] o2);
    assign o1 = (x < y) ? x : y;
    assign o2 = (x < y) ? y : x;
endmodule

// --- bitonic_sort4_8_cmpdesc : descending compare-exchange (o1 = max, o2 = min) ---
module bitonic_sort4_8_cmpdesc(input [7:0] x, input [7:0] y, output [7:0] o1, output [7:0] o2);
    assign o1 = (x > y) ? x : y;
    assign o2 = (x > y) ? y : x;
endmodule

module bitonic_sort4_8(input [7:0] in0, input [7:0] in1, input [7:0] in2, input [7:0] in3, output [7:0] out0, output [7:0] out1, output [7:0] out2, output [7:0] out3);
    // define out0 output 120.255.160
    wire [7:0] b0, b1;
    wire [7:0] b2, b3;
    wire [7:0] b4, b5;
    wire [7:0] b6, b7;
    wire [7:0] b8, b9;
    wire [7:0] b10, b11;
    bitonic_sort4_8_cmpasc u_c0(.x(in0), .y(in1), .o1(b0), .o2(b1));
    bitonic_sort4_8_cmpdesc u_c1(.x(in2), .y(in3), .o1(b2), .o2(b3));
    bitonic_sort4_8_cmpasc u_c2(.x(b0), .y(b2), .o1(b4), .o2(b5));
    bitonic_sort4_8_cmpasc u_c3(.x(b1), .y(b3), .o1(b6), .o2(b7));
    bitonic_sort4_8_cmpasc u_c4(.x(b4), .y(b6), .o1(b8), .o2(b9));
    bitonic_sort4_8_cmpasc u_c5(.x(b5), .y(b7), .o1(b10), .o2(b11));
    assign out0 = b8;
    assign out1 = b9;
    assign out2 = b10;
    assign out3 = b11;
endmodule


