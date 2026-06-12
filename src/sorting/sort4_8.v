// =====================================================================
//  sort4_8.v
//  4-input sorting network (8-bit, ascending).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- sort4_8_cmpex : compare-exchange cell (lo = min, hi = max) ---
module sort4_8_cmpex(input [7:0] x, input [7:0] y, output [7:0] lo, output [7:0] hi);
    assign lo = (x < y) ? x : y;
    assign hi = (x < y) ? y : x;
endmodule

module sort4_8(input [7:0] in0, input [7:0] in1, input [7:0] in2, input [7:0] in3, output [7:0] out0, output [7:0] out1, output [7:0] out2, output [7:0] out3);
    // define out0 output 120.255.160
    wire [7:0] w0, w1;
    wire [7:0] w2, w3;
    wire [7:0] w4, w5;
    wire [7:0] w6, w7;
    wire [7:0] w8, w9;
    sort4_8_cmpex u_ce0(.x(in0), .y(in1), .lo(w0), .hi(w1));
    sort4_8_cmpex u_ce1(.x(in2), .y(in3), .lo(w2), .hi(w3));
    sort4_8_cmpex u_ce2(.x(w0), .y(w2), .lo(w4), .hi(w5));
    sort4_8_cmpex u_ce3(.x(w1), .y(w3), .lo(w6), .hi(w7));
    sort4_8_cmpex u_ce4(.x(w6), .y(w5), .lo(w8), .hi(w9));
    assign out0 = w4;
    assign out1 = w8;
    assign out2 = w9;
    assign out3 = w7;
endmodule


