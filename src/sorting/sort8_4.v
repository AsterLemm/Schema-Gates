// =====================================================================
//  sort8_4.v
//  8-input sorting network (4-bit, ascending).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- sort8_4_cmpex : compare-exchange cell (lo = min, hi = max) ---
module sort8_4_cmpex(input [3:0] x, input [3:0] y, output [3:0] lo, output [3:0] hi);
    assign lo = (x < y) ? x : y;
    assign hi = (x < y) ? y : x;
endmodule

module sort8_4(input [3:0] in0, input [3:0] in1, input [3:0] in2, input [3:0] in3, input [3:0] in4, input [3:0] in5, input [3:0] in6, input [3:0] in7, output [3:0] out0, output [3:0] out1, output [3:0] out2, output [3:0] out3, output [3:0] out4, output [3:0] out5, output [3:0] out6, output [3:0] out7);
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
    sort8_4_cmpex u_ce0(.x(in0), .y(in1), .lo(w0), .hi(w1));
    sort8_4_cmpex u_ce1(.x(in2), .y(in3), .lo(w2), .hi(w3));
    sort8_4_cmpex u_ce2(.x(in4), .y(in5), .lo(w4), .hi(w5));
    sort8_4_cmpex u_ce3(.x(in6), .y(in7), .lo(w6), .hi(w7));
    sort8_4_cmpex u_ce4(.x(w0), .y(w2), .lo(w8), .hi(w9));
    sort8_4_cmpex u_ce5(.x(w1), .y(w3), .lo(w10), .hi(w11));
    sort8_4_cmpex u_ce6(.x(w4), .y(w6), .lo(w12), .hi(w13));
    sort8_4_cmpex u_ce7(.x(w5), .y(w7), .lo(w14), .hi(w15));
    sort8_4_cmpex u_ce8(.x(w10), .y(w9), .lo(w16), .hi(w17));
    sort8_4_cmpex u_ce9(.x(w14), .y(w13), .lo(w18), .hi(w19));
    sort8_4_cmpex u_ce10(.x(w8), .y(w12), .lo(w20), .hi(w21));
    sort8_4_cmpex u_ce11(.x(w11), .y(w15), .lo(w22), .hi(w23));
    sort8_4_cmpex u_ce12(.x(w16), .y(w18), .lo(w24), .hi(w25));
    sort8_4_cmpex u_ce13(.x(w17), .y(w19), .lo(w26), .hi(w27));
    sort8_4_cmpex u_ce14(.x(w24), .y(w21), .lo(w28), .hi(w29));
    sort8_4_cmpex u_ce15(.x(w22), .y(w27), .lo(w30), .hi(w31));
    sort8_4_cmpex u_ce16(.x(w26), .y(w29), .lo(w32), .hi(w33));
    sort8_4_cmpex u_ce17(.x(w30), .y(w25), .lo(w34), .hi(w35));
    sort8_4_cmpex u_ce18(.x(w34), .y(w33), .lo(w36), .hi(w37));
    assign out0 = w20;
    assign out1 = w28;
    assign out2 = w32;
    assign out3 = w36;
    assign out4 = w37;
    assign out5 = w35;
    assign out6 = w31;
    assign out7 = w23;
endmodule


