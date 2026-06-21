// =====================================================================
//  decoder2to4_en.v
//  2-to-4 decoder with enable.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module decoder2to4_en(input [1:0] a, input en, output [3:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    // define en input 255.180.80
    assign y[0] = en & (~a[0] & ~a[1]);
    assign y[1] = en & (a[0] & ~a[1]);
    assign y[2] = en & (~a[0] & a[1]);
    assign y[3] = en & (a[0] & a[1]);
endmodule


