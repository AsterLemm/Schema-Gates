// =====================================================================
//  encoder8to3.v
//  8-to-3 binary encoder (one-hot input assumed).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module encoder8to3(input [7:0] a, output [2:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y[0] = a[1] | a[3] | a[5] | a[7];
    assign y[1] = a[2] | a[3] | a[6] | a[7];
    assign y[2] = a[4] | a[5] | a[6] | a[7];
endmodule


