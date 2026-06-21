// =====================================================================
//  reciprocal_seed16.v
//  16-bit reciprocal seed (structural leading-one reflect); no arithmetic operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- reciprocal_seed16_lead : leading-one detector (one-hot ms[k]) ---
module reciprocal_seed16_lead(input [15:0] a, output [15:0] ms);
    assign ms[0] = a[0] & ~(a[1] | a[2] | a[3] | a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[0] is the leading one
    assign ms[1] = a[1] & ~(a[2] | a[3] | a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[1] is the leading one
    assign ms[2] = a[2] & ~(a[3] | a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[2] is the leading one
    assign ms[3] = a[3] & ~(a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[3] is the leading one
    assign ms[4] = a[4] & ~(a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[4] is the leading one
    assign ms[5] = a[5] & ~(a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[5] is the leading one
    assign ms[6] = a[6] & ~(a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[6] is the leading one
    assign ms[7] = a[7] & ~(a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[7] is the leading one
    assign ms[8] = a[8] & ~(a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[8] is the leading one
    assign ms[9] = a[9] & ~(a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[9] is the leading one
    assign ms[10] = a[10] & ~(a[11] | a[12] | a[13] | a[14] | a[15]);   // a[10] is the leading one
    assign ms[11] = a[11] & ~(a[12] | a[13] | a[14] | a[15]);   // a[11] is the leading one
    assign ms[12] = a[12] & ~(a[13] | a[14] | a[15]);   // a[12] is the leading one
    assign ms[13] = a[13] & ~(a[14] | a[15]);   // a[13] is the leading one
    assign ms[14] = a[14] & ~(a[15]);   // a[14] is the leading one
    assign ms[15] = a[15] & ~(1'b0);   // a[15] is the leading one
endmodule

module reciprocal_seed16(input [15:0] a, output [15:0] seed);
    // define a input 80.160.255
    // define seed output 120.255.160
    // seed = 2^(W-1-msb(a)) : reflect leading-one position (priority logic)
    wire [15:0] ms;
    reciprocal_seed16_lead u_lead(.a(a), .ms(ms));
    assign seed = {ms[0], ms[1], ms[2], ms[3], ms[4], ms[5], ms[6], ms[7], ms[8], ms[9], ms[10], ms[11], ms[12], ms[13], ms[14], ms[15]};
endmodule


