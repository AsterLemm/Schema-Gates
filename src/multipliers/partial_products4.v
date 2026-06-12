// =====================================================================
//  partial_products4.v
//  4x4 partial-product AND matrix.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- partial_products4_row : one rank of the AND matrix (one b bit) ---
module partial_products4_row(input [3:0] a, input bbit, output [3:0] ppr);
    assign ppr[0] = a[0] & bbit;
    assign ppr[1] = a[1] & bbit;
    assign ppr[2] = a[2] & bbit;
    assign ppr[3] = a[3] & bbit;
endmodule

module partial_products4(input [3:0] a, input [3:0] b, output [15:0] pp);
    // define a input 80.160.255   // define b input 80.200.255   // define pp output 120.255.160
    // one row instance per b bit: pp[i*4+j] = a[j] & b[i], as before
    partial_products4_row u_row0(.a(a), .bbit(b[0]), .ppr(pp[3:0]));
    partial_products4_row u_row1(.a(a), .bbit(b[1]), .ppr(pp[7:4]));
    partial_products4_row u_row2(.a(a), .bbit(b[2]), .ppr(pp[11:8]));
    partial_products4_row u_row3(.a(a), .bbit(b[3]), .ppr(pp[15:12]));
endmodule


