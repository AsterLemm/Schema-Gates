// =====================================================================
//  encoder32to5.v
//  32-to-5 binary encoder (one-hot input assumed).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module encoder32to5(input [31:0] a, output [4:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y[0] = a[1] | a[3] | a[5] | a[7] | a[9] | a[11] | a[13] | a[15] | a[17] | a[19] | a[21] | a[23] | a[25] | a[27] | a[29] | a[31];
    assign y[1] = a[2] | a[3] | a[6] | a[7] | a[10] | a[11] | a[14] | a[15] | a[18] | a[19] | a[22] | a[23] | a[26] | a[27] | a[30] | a[31];
    assign y[2] = a[4] | a[5] | a[6] | a[7] | a[12] | a[13] | a[14] | a[15] | a[20] | a[21] | a[22] | a[23] | a[28] | a[29] | a[30] | a[31];
    assign y[3] = a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31];
    assign y[4] = a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31];
endmodule


