// =====================================================================
//  reciprocal_seed32.v
//  32-bit reciprocal seed (structural leading-one reflect); no arithmetic operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- reciprocal_seed32_lead : leading-one detector (one-hot ms[k]) ---
module reciprocal_seed32_lead(input [31:0] a, output [31:0] ms);
    assign ms[0] = a[0] & ~(a[1] | a[2] | a[3] | a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[0] is the leading one
    assign ms[1] = a[1] & ~(a[2] | a[3] | a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[1] is the leading one
    assign ms[2] = a[2] & ~(a[3] | a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[2] is the leading one
    assign ms[3] = a[3] & ~(a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[3] is the leading one
    assign ms[4] = a[4] & ~(a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[4] is the leading one
    assign ms[5] = a[5] & ~(a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[5] is the leading one
    assign ms[6] = a[6] & ~(a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[6] is the leading one
    assign ms[7] = a[7] & ~(a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[7] is the leading one
    assign ms[8] = a[8] & ~(a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[8] is the leading one
    assign ms[9] = a[9] & ~(a[10] | a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[9] is the leading one
    assign ms[10] = a[10] & ~(a[11] | a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[10] is the leading one
    assign ms[11] = a[11] & ~(a[12] | a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[11] is the leading one
    assign ms[12] = a[12] & ~(a[13] | a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[12] is the leading one
    assign ms[13] = a[13] & ~(a[14] | a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[13] is the leading one
    assign ms[14] = a[14] & ~(a[15] | a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[14] is the leading one
    assign ms[15] = a[15] & ~(a[16] | a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[15] is the leading one
    assign ms[16] = a[16] & ~(a[17] | a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[16] is the leading one
    assign ms[17] = a[17] & ~(a[18] | a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[17] is the leading one
    assign ms[18] = a[18] & ~(a[19] | a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[18] is the leading one
    assign ms[19] = a[19] & ~(a[20] | a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[19] is the leading one
    assign ms[20] = a[20] & ~(a[21] | a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[20] is the leading one
    assign ms[21] = a[21] & ~(a[22] | a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[21] is the leading one
    assign ms[22] = a[22] & ~(a[23] | a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[22] is the leading one
    assign ms[23] = a[23] & ~(a[24] | a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[23] is the leading one
    assign ms[24] = a[24] & ~(a[25] | a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[24] is the leading one
    assign ms[25] = a[25] & ~(a[26] | a[27] | a[28] | a[29] | a[30] | a[31]);   // a[25] is the leading one
    assign ms[26] = a[26] & ~(a[27] | a[28] | a[29] | a[30] | a[31]);   // a[26] is the leading one
    assign ms[27] = a[27] & ~(a[28] | a[29] | a[30] | a[31]);   // a[27] is the leading one
    assign ms[28] = a[28] & ~(a[29] | a[30] | a[31]);   // a[28] is the leading one
    assign ms[29] = a[29] & ~(a[30] | a[31]);   // a[29] is the leading one
    assign ms[30] = a[30] & ~(a[31]);   // a[30] is the leading one
    assign ms[31] = a[31] & ~(1'b0);   // a[31] is the leading one
endmodule

module reciprocal_seed32(input [31:0] a, output [31:0] seed);
    // define a input 80.160.255
    // define seed output 120.255.160
    // seed = 2^(W-1-msb(a)) : reflect leading-one position (priority logic)
    wire [31:0] ms;
    reciprocal_seed32_lead u_lead(.a(a), .ms(ms));
    assign seed = {ms[0], ms[1], ms[2], ms[3], ms[4], ms[5], ms[6], ms[7], ms[8], ms[9], ms[10], ms[11], ms[12], ms[13], ms[14], ms[15], ms[16], ms[17], ms[18], ms[19], ms[20], ms[21], ms[22], ms[23], ms[24], ms[25], ms[26], ms[27], ms[28], ms[29], ms[30], ms[31]};
endmodule


