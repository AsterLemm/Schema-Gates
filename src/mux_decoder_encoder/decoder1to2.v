// =====================================================================
//  decoder1to2.v
//  1-to-2 one-hot decoder.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module decoder1to2(input [0:0] a, output [1:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y[0] = (~a[0]);
    assign y[1] = (a[0]);
endmodule


