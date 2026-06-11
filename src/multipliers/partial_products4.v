// =====================================================================
//  partial_products4.v
//  4x4 partial-product AND matrix.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module partial_products4(input [3:0] a, input [3:0] b, output [15:0] pp);
    // define a input 80.160.255   // define b input 80.200.255   // define pp output 120.255.160
    assign pp[0] = a[0] & b[0];
    assign pp[1] = a[1] & b[0];
    assign pp[2] = a[2] & b[0];
    assign pp[3] = a[3] & b[0];
    assign pp[4] = a[0] & b[1];
    assign pp[5] = a[1] & b[1];
    assign pp[6] = a[2] & b[1];
    assign pp[7] = a[3] & b[1];
    assign pp[8] = a[0] & b[2];
    assign pp[9] = a[1] & b[2];
    assign pp[10] = a[2] & b[2];
    assign pp[11] = a[3] & b[2];
    assign pp[12] = a[0] & b[3];
    assign pp[13] = a[1] & b[3];
    assign pp[14] = a[2] & b[3];
    assign pp[15] = a[3] & b[3];
endmodule


