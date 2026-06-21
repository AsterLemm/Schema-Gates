// =====================================================================
//  bitonic_sort8_8.v
//  8-input bitonic sorting network (8-bit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- bitonic_sort8_8_cmpasc : ascending compare-exchange (o1 = min, o2 = max) ---
module bitonic_sort8_8_cmpasc(input [7:0] x, input [7:0] y, output [7:0] o1, output [7:0] o2);
    assign o1 = (x < y) ? x : y;
    assign o2 = (x < y) ? y : x;
endmodule

// --- bitonic_sort8_8_cmpdesc : descending compare-exchange (o1 = max, o2 = min) ---
module bitonic_sort8_8_cmpdesc(input [7:0] x, input [7:0] y, output [7:0] o1, output [7:0] o2);
    assign o1 = (x > y) ? x : y;
    assign o2 = (x > y) ? y : x;
endmodule

module bitonic_sort8_8(input [7:0] in0, input [7:0] in1, input [7:0] in2, input [7:0] in3, input [7:0] in4, input [7:0] in5, input [7:0] in6, input [7:0] in7, output [7:0] out0, output [7:0] out1, output [7:0] out2, output [7:0] out3, output [7:0] out4, output [7:0] out5, output [7:0] out6, output [7:0] out7);
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
    bitonic_sort8_8_cmpasc u_c0(.x(in0), .y(in1), .o1(b0), .o2(b1));
    bitonic_sort8_8_cmpdesc u_c1(.x(in2), .y(in3), .o1(b2), .o2(b3));
    bitonic_sort8_8_cmpasc u_c2(.x(b0), .y(b2), .o1(b4), .o2(b5));
    bitonic_sort8_8_cmpasc u_c3(.x(b1), .y(b3), .o1(b6), .o2(b7));
    bitonic_sort8_8_cmpasc u_c4(.x(b4), .y(b6), .o1(b8), .o2(b9));
    bitonic_sort8_8_cmpasc u_c5(.x(b5), .y(b7), .o1(b10), .o2(b11));
    bitonic_sort8_8_cmpasc u_c6(.x(in4), .y(in5), .o1(b12), .o2(b13));
    bitonic_sort8_8_cmpdesc u_c7(.x(in6), .y(in7), .o1(b14), .o2(b15));
    bitonic_sort8_8_cmpdesc u_c8(.x(b12), .y(b14), .o1(b16), .o2(b17));
    bitonic_sort8_8_cmpdesc u_c9(.x(b13), .y(b15), .o1(b18), .o2(b19));
    bitonic_sort8_8_cmpdesc u_c10(.x(b16), .y(b18), .o1(b20), .o2(b21));
    bitonic_sort8_8_cmpdesc u_c11(.x(b17), .y(b19), .o1(b22), .o2(b23));
    bitonic_sort8_8_cmpasc u_c12(.x(b8), .y(b20), .o1(b24), .o2(b25));
    bitonic_sort8_8_cmpasc u_c13(.x(b9), .y(b21), .o1(b26), .o2(b27));
    bitonic_sort8_8_cmpasc u_c14(.x(b10), .y(b22), .o1(b28), .o2(b29));
    bitonic_sort8_8_cmpasc u_c15(.x(b11), .y(b23), .o1(b30), .o2(b31));
    bitonic_sort8_8_cmpasc u_c16(.x(b24), .y(b28), .o1(b32), .o2(b33));
    bitonic_sort8_8_cmpasc u_c17(.x(b26), .y(b30), .o1(b34), .o2(b35));
    bitonic_sort8_8_cmpasc u_c18(.x(b32), .y(b34), .o1(b36), .o2(b37));
    bitonic_sort8_8_cmpasc u_c19(.x(b33), .y(b35), .o1(b38), .o2(b39));
    bitonic_sort8_8_cmpasc u_c20(.x(b25), .y(b29), .o1(b40), .o2(b41));
    bitonic_sort8_8_cmpasc u_c21(.x(b27), .y(b31), .o1(b42), .o2(b43));
    bitonic_sort8_8_cmpasc u_c22(.x(b40), .y(b42), .o1(b44), .o2(b45));
    bitonic_sort8_8_cmpasc u_c23(.x(b41), .y(b43), .o1(b46), .o2(b47));
    assign out0 = b36;
    assign out1 = b37;
    assign out2 = b38;
    assign out3 = b39;
    assign out4 = b44;
    assign out5 = b45;
    assign out6 = b46;
    assign out7 = b47;
endmodule


