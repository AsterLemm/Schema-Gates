// =====================================================================
//  reciprocal_seed32.v
//  32-bit reciprocal seed (structural leading-one reflect); no arithmetic operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module reciprocal_seed32(input [31:0] a, output [31:0] seed);
    // define a input 80.160.255   // define seed output 120.255.160
    // seed = 2^(W-1-msb(a)) : reflect leading-one position (priority logic)
    wire ms0 = a[0] & ~(a[1] | a[2] | a[3] | a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[0] is the leading one
    wire ms1 = a[1] & ~(a[2] | a[3] | a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[1] is the leading one
    wire ms2 = a[2] & ~(a[3] | a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[2] is the leading one
    wire ms3 = a[3] & ~(a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[3] is the leading one
    wire ms4 = a[4] & ~(a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[4] is the leading one
    wire ms5 = a[5] & ~(a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[5] is the leading one
    wire ms6 = a[6] & ~(a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[6] is the leading one
    wire ms7 = a[7] & ~(a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[7] is the leading one
    wire ms8 = a[8] & ~(a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[8] is the leading one
    wire ms9 = a[9] & ~(a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[9] is the leading one
    wire ms10 = a[10] & ~(a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[10] is the leading one
    wire ms11 = a[11] & ~(a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[11] is the leading one
    wire ms12 = a[12] & ~(a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[12] is the leading one
    wire ms13 = a[13] & ~(a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[13] is the leading one
    wire ms14 = a[14] & ~(a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[14] is the leading one
    wire ms15 = a[15] & ~(a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[15] is the leading one
    wire ms16 = a[16] & ~(a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[16] is the leading one
    wire ms17 = a[17] & ~(a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[17] is the leading one
    wire ms18 = a[18] & ~(a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[18] is the leading one
    wire ms19 = a[19] & ~(a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[19] is the leading one
    wire ms20 = a[20] & ~(a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[20] is the leading one
    wire ms21 = a[21] & ~(a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[21] is the leading one
    wire ms22 = a[22] & ~(a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[22] is the leading one
    wire ms23 = a[23] & ~(a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[23] is the leading one
    wire ms24 = a[24] & ~(a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[24] is the leading one
    wire ms25 = a[25] & ~(a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[25] is the leading one
    wire ms26 = a[26] & ~(a[27] | a[28] | a[29] | a[30] | a[31]);   // a[26] is the leading one
    wire ms27 = a[27] & ~(a[28] | a[29] | a[30] | a[31]);   // a[27] is the leading one
    wire ms28 = a[28] & ~(a[29] | a[30] | a[31]);   // a[28] is the leading one
    wire ms29 = a[29] & ~(a[30] | a[31]);   // a[29] is the leading one
    wire ms30 = a[30] & ~(a[31]);   // a[30] is the leading one
    wire ms31 = a[31] & ~(1'b0);   // a[31] is the leading one
    assign seed = {ms0, ms1, ms2, ms3, ms4, ms5, ms6, ms7, ms8, ms9, ms10, ms11, ms12, ms13, ms14, ms15, ms16, ms17, ms18, ms19, ms20, ms21, ms22, ms23, ms24, ms25, ms26, ms27, ms28, ms29, ms30, ms31};
endmodule


