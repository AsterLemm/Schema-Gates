// =====================================================================
//  onehot_to_bin16.v
//  One-hot->binary (16 lines).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module onehot_to_bin16(input [15:0] a, output [3:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y[0] = a[1] | a[3] | a[5] | a[7] | a[9] | a[11] | a[13] | a[15];
    assign y[1] = a[2] | a[3] | a[6] | a[7] | a[10] | a[11] | a[14] | a[15];
    assign y[2] = a[4] | a[5] | a[6] | a[7] | a[12] | a[13] | a[14] | a[15];
    assign y[3] = a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15];
endmodule


