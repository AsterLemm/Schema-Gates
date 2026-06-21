// =====================================================================
//  abs_twos4.v
//  4-bit two's-complement absolute value.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module abs_twos4(input signed [3:0] a, output [3:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y = a[3] ? ((~a) + 1'b1) : a;   // |a|
endmodule


