// =====================================================================
//  reciprocal_seed16.v
//  16-bit reciprocal seed (structural leading-one reflect); no arithmetic operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module reciprocal_seed16(input [15:0] a, output [15:0] seed);
    // define a input 80.160.255   // define seed output 120.255.160
    // seed = 2^(W-1-msb(a)) : reflect leading-one position (priority logic)
    wire ms0 = a[0] & ~(a[1] | a[2] | a[3] | a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[0] is the leading one
    wire ms1 = a[1] & ~(a[2] | a[3] | a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[1] is the leading one
    wire ms2 = a[2] & ~(a[3] | a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[2] is the leading one
    wire ms3 = a[3] & ~(a[4] | a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[3] is the leading one
    wire ms4 = a[4] & ~(a[5] | a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[4] is the leading one
    wire ms5 = a[5] & ~(a[6] | a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[5] is the leading one
    wire ms6 = a[6] & ~(a[7] | a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[6] is the leading one
    wire ms7 = a[7] & ~(a[8] | a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[7] is the leading one
    wire ms8 = a[8] & ~(a[9] | a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[8] is the leading one
    wire ms9 = a[9] & ~(a[10] | a[11] | a[12] | a[13] | a[14] | a[15]);   // a[9] is the leading one
    wire ms10 = a[10] & ~(a[11] | a[12] | a[13] | a[14] | a[15]);   // a[10] is the leading one
    wire ms11 = a[11] & ~(a[12] | a[13] | a[14] | a[15]);   // a[11] is the leading one
    wire ms12 = a[12] & ~(a[13] | a[14] | a[15]);   // a[12] is the leading one
    wire ms13 = a[13] & ~(a[14] | a[15]);   // a[13] is the leading one
    wire ms14 = a[14] & ~(a[15]);   // a[14] is the leading one
    wire ms15 = a[15] & ~(1'b0);   // a[15] is the leading one
    assign seed = {ms0, ms1, ms2, ms3, ms4, ms5, ms6, ms7, ms8, ms9, ms10, ms11, ms12, ms13, ms14, ms15};
endmodule


