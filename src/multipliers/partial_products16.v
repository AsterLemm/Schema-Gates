// =====================================================================
//  partial_products16.v
//  16x16 partial-product AND matrix.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- partial_products16_row : one rank of the AND matrix (one b bit) ---
module partial_products16_row(input [15:0] a, input bbit, output [15:0] ppr);
    assign ppr[0] = a[0] & bbit;
    assign ppr[1] = a[1] & bbit;
    assign ppr[2] = a[2] & bbit;
    assign ppr[3] = a[3] & bbit;
    assign ppr[4] = a[4] & bbit;
    assign ppr[5] = a[5] & bbit;
    assign ppr[6] = a[6] & bbit;
    assign ppr[7] = a[7] & bbit;
    assign ppr[8] = a[8] & bbit;
    assign ppr[9] = a[9] & bbit;
    assign ppr[10] = a[10] & bbit;
    assign ppr[11] = a[11] & bbit;
    assign ppr[12] = a[12] & bbit;
    assign ppr[13] = a[13] & bbit;
    assign ppr[14] = a[14] & bbit;
    assign ppr[15] = a[15] & bbit;
endmodule

module partial_products16(input [15:0] a, input [15:0] b, output [255:0] pp);
    // define a input 80.160.255
    // define b input 80.200.255
    // define pp output 120.255.160
    // one row instance per b bit: pp[i*16+j] = a[j] & b[i], as before
    partial_products16_row u_row0(.a(a), .bbit(b[0]), .ppr(pp[15:0]));
    partial_products16_row u_row1(.a(a), .bbit(b[1]), .ppr(pp[31:16]));
    partial_products16_row u_row2(.a(a), .bbit(b[2]), .ppr(pp[47:32]));
    partial_products16_row u_row3(.a(a), .bbit(b[3]), .ppr(pp[63:48]));
    partial_products16_row u_row4(.a(a), .bbit(b[4]), .ppr(pp[79:64]));
    partial_products16_row u_row5(.a(a), .bbit(b[5]), .ppr(pp[95:80]));
    partial_products16_row u_row6(.a(a), .bbit(b[6]), .ppr(pp[111:96]));
    partial_products16_row u_row7(.a(a), .bbit(b[7]), .ppr(pp[127:112]));
    partial_products16_row u_row8(.a(a), .bbit(b[8]), .ppr(pp[143:128]));
    partial_products16_row u_row9(.a(a), .bbit(b[9]), .ppr(pp[159:144]));
    partial_products16_row u_row10(.a(a), .bbit(b[10]), .ppr(pp[175:160]));
    partial_products16_row u_row11(.a(a), .bbit(b[11]), .ppr(pp[191:176]));
    partial_products16_row u_row12(.a(a), .bbit(b[12]), .ppr(pp[207:192]));
    partial_products16_row u_row13(.a(a), .bbit(b[13]), .ppr(pp[223:208]));
    partial_products16_row u_row14(.a(a), .bbit(b[14]), .ppr(pp[239:224]));
    partial_products16_row u_row15(.a(a), .bbit(b[15]), .ppr(pp[255:240]));
endmodule


