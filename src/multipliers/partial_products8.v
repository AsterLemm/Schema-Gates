// =====================================================================
//  partial_products8.v
//  8x8 partial-product AND matrix.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module partial_products8(input [7:0] a, input [7:0] b, output [63:0] pp);
    // define a input 80.160.255   // define b input 80.200.255   // define pp output 120.255.160
    assign pp[0] = a[0] & b[0];
    assign pp[1] = a[1] & b[0];
    assign pp[2] = a[2] & b[0];
    assign pp[3] = a[3] & b[0];
    assign pp[4] = a[4] & b[0];
    assign pp[5] = a[5] & b[0];
    assign pp[6] = a[6] & b[0];
    assign pp[7] = a[7] & b[0];
    assign pp[8] = a[0] & b[1];
    assign pp[9] = a[1] & b[1];
    assign pp[10] = a[2] & b[1];
    assign pp[11] = a[3] & b[1];
    assign pp[12] = a[4] & b[1];
    assign pp[13] = a[5] & b[1];
    assign pp[14] = a[6] & b[1];
    assign pp[15] = a[7] & b[1];
    assign pp[16] = a[0] & b[2];
    assign pp[17] = a[1] & b[2];
    assign pp[18] = a[2] & b[2];
    assign pp[19] = a[3] & b[2];
    assign pp[20] = a[4] & b[2];
    assign pp[21] = a[5] & b[2];
    assign pp[22] = a[6] & b[2];
    assign pp[23] = a[7] & b[2];
    assign pp[24] = a[0] & b[3];
    assign pp[25] = a[1] & b[3];
    assign pp[26] = a[2] & b[3];
    assign pp[27] = a[3] & b[3];
    assign pp[28] = a[4] & b[3];
    assign pp[29] = a[5] & b[3];
    assign pp[30] = a[6] & b[3];
    assign pp[31] = a[7] & b[3];
    assign pp[32] = a[0] & b[4];
    assign pp[33] = a[1] & b[4];
    assign pp[34] = a[2] & b[4];
    assign pp[35] = a[3] & b[4];
    assign pp[36] = a[4] & b[4];
    assign pp[37] = a[5] & b[4];
    assign pp[38] = a[6] & b[4];
    assign pp[39] = a[7] & b[4];
    assign pp[40] = a[0] & b[5];
    assign pp[41] = a[1] & b[5];
    assign pp[42] = a[2] & b[5];
    assign pp[43] = a[3] & b[5];
    assign pp[44] = a[4] & b[5];
    assign pp[45] = a[5] & b[5];
    assign pp[46] = a[6] & b[5];
    assign pp[47] = a[7] & b[5];
    assign pp[48] = a[0] & b[6];
    assign pp[49] = a[1] & b[6];
    assign pp[50] = a[2] & b[6];
    assign pp[51] = a[3] & b[6];
    assign pp[52] = a[4] & b[6];
    assign pp[53] = a[5] & b[6];
    assign pp[54] = a[6] & b[6];
    assign pp[55] = a[7] & b[6];
    assign pp[56] = a[0] & b[7];
    assign pp[57] = a[1] & b[7];
    assign pp[58] = a[2] & b[7];
    assign pp[59] = a[3] & b[7];
    assign pp[60] = a[4] & b[7];
    assign pp[61] = a[5] & b[7];
    assign pp[62] = a[6] & b[7];
    assign pp[63] = a[7] & b[7];
endmodule


