// =====================================================================
//  encoder2to1.v
//  2-to-1 binary encoder (one-hot input assumed).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module encoder2to1(input [1:0] a, output [0:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y[0] = a[1];
endmodule


