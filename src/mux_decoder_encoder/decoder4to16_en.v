// =====================================================================
//  decoder4to16_en.v
//  4-to-16 decoder with enable.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module decoder4to16_en(input [3:0] a, input en, output [15:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    // define en input 255.180.80
    assign y[0] = en & (~a[0] & ~a[1] & ~a[2] & ~a[3]);
    assign y[1] = en & (a[0] & ~a[1] & ~a[2] & ~a[3]);
    assign y[2] = en & (~a[0] & a[1] & ~a[2] & ~a[3]);
    assign y[3] = en & (a[0] & a[1] & ~a[2] & ~a[3]);
    assign y[4] = en & (~a[0] & ~a[1] & a[2] & ~a[3]);
    assign y[5] = en & (a[0] & ~a[1] & a[2] & ~a[3]);
    assign y[6] = en & (~a[0] & a[1] & a[2] & ~a[3]);
    assign y[7] = en & (a[0] & a[1] & a[2] & ~a[3]);
    assign y[8] = en & (~a[0] & ~a[1] & ~a[2] & a[3]);
    assign y[9] = en & (a[0] & ~a[1] & ~a[2] & a[3]);
    assign y[10] = en & (~a[0] & a[1] & ~a[2] & a[3]);
    assign y[11] = en & (a[0] & a[1] & ~a[2] & a[3]);
    assign y[12] = en & (~a[0] & ~a[1] & a[2] & a[3]);
    assign y[13] = en & (a[0] & ~a[1] & a[2] & a[3]);
    assign y[14] = en & (~a[0] & a[1] & a[2] & a[3]);
    assign y[15] = en & (a[0] & a[1] & a[2] & a[3]);
endmodule


