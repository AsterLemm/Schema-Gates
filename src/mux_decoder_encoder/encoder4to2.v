// =====================================================================
//  encoder4to2.v
//  4-to-2 binary encoder (one-hot input assumed).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module encoder4to2(input [3:0] a, output [1:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y[0] = a[1] | a[3];
    assign y[1] = a[2] | a[3];
endmodule


