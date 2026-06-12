// =====================================================================
//  partial_products8.v
//  8x8 partial-product AND matrix.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- partial_products8_row : one rank of the AND matrix (one b bit) ---
module partial_products8_row(input [7:0] a, input bbit, output [7:0] ppr);
    assign ppr[0] = a[0] & bbit;
    assign ppr[1] = a[1] & bbit;
    assign ppr[2] = a[2] & bbit;
    assign ppr[3] = a[3] & bbit;
    assign ppr[4] = a[4] & bbit;
    assign ppr[5] = a[5] & bbit;
    assign ppr[6] = a[6] & bbit;
    assign ppr[7] = a[7] & bbit;
endmodule

module partial_products8(input [7:0] a, input [7:0] b, output [63:0] pp);
    // define a input 80.160.255   // define b input 80.200.255   // define pp output 120.255.160
    // one row instance per b bit: pp[i*8+j] = a[j] & b[i], as before
    partial_products8_row u_row0(.a(a), .bbit(b[0]), .ppr(pp[7:0]));
    partial_products8_row u_row1(.a(a), .bbit(b[1]), .ppr(pp[15:8]));
    partial_products8_row u_row2(.a(a), .bbit(b[2]), .ppr(pp[23:16]));
    partial_products8_row u_row3(.a(a), .bbit(b[3]), .ppr(pp[31:24]));
    partial_products8_row u_row4(.a(a), .bbit(b[4]), .ppr(pp[39:32]));
    partial_products8_row u_row5(.a(a), .bbit(b[5]), .ppr(pp[47:40]));
    partial_products8_row u_row6(.a(a), .bbit(b[6]), .ppr(pp[55:48]));
    partial_products8_row u_row7(.a(a), .bbit(b[7]), .ppr(pp[63:56]));
endmodule


