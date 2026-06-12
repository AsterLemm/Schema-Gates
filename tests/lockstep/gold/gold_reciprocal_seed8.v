// =====================================================================
//  reciprocal_seed8.v
//  8-bit reciprocal seed (structural leading-one reflect); no arithmetic operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_reciprocal_seed8(input [7:0] a, output [7:0] seed);
    // define a input 80.160.255   // define seed output 120.255.160
    // seed = 2^(W-1-msb(a)) : reflect leading-one position (priority logic)
    wire ms0 = a[0] & ~(a[1] | a[2] | a[3] | a[4] | a[5] | a[6] | a[7]);   // a[0] is the leading one
    wire ms1 = a[1] & ~(a[2] | a[3] | a[4] | a[5] | a[6] | a[7]);   // a[1] is the leading one
    wire ms2 = a[2] & ~(a[3] | a[4] | a[5] | a[6] | a[7]);   // a[2] is the leading one
    wire ms3 = a[3] & ~(a[4] | a[5] | a[6] | a[7]);   // a[3] is the leading one
    wire ms4 = a[4] & ~(a[5] | a[6] | a[7]);   // a[4] is the leading one
    wire ms5 = a[5] & ~(a[6] | a[7]);   // a[5] is the leading one
    wire ms6 = a[6] & ~(a[7]);   // a[6] is the leading one
    wire ms7 = a[7] & ~(1'b0);   // a[7] is the leading one
    assign seed = {ms0, ms1, ms2, ms3, ms4, ms5, ms6, ms7};
endmodule


