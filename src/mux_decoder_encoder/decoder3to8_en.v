// =====================================================================
//  decoder3to8_en.v
//  3-to-8 decoder with enable.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module decoder3to8_en(input [2:0] a, input en, output [7:0] y);
    // define a input 80.160.255   // define y output 120.255.160   // define en input 255.180.80
    assign y[0] = en & (~a[0] & ~a[1] & ~a[2]);
    assign y[1] = en & (a[0] & ~a[1] & ~a[2]);
    assign y[2] = en & (~a[0] & a[1] & ~a[2]);
    assign y[3] = en & (a[0] & a[1] & ~a[2]);
    assign y[4] = en & (~a[0] & ~a[1] & a[2]);
    assign y[5] = en & (a[0] & ~a[1] & a[2]);
    assign y[6] = en & (~a[0] & a[1] & a[2]);
    assign y[7] = en & (a[0] & a[1] & a[2]);
endmodule


