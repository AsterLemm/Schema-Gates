// =====================================================================
//  partial_products32.v
//  32x32 partial-product AND matrix.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- partial_products32_row : one rank of the AND matrix (one b bit) ---
module partial_products32_row(input [31:0] a, input bbit, output [31:0] ppr);
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
    assign ppr[16] = a[16] & bbit;
    assign ppr[17] = a[17] & bbit;
    assign ppr[18] = a[18] & bbit;
    assign ppr[19] = a[19] & bbit;
    assign ppr[20] = a[20] & bbit;
    assign ppr[21] = a[21] & bbit;
    assign ppr[22] = a[22] & bbit;
    assign ppr[23] = a[23] & bbit;
    assign ppr[24] = a[24] & bbit;
    assign ppr[25] = a[25] & bbit;
    assign ppr[26] = a[26] & bbit;
    assign ppr[27] = a[27] & bbit;
    assign ppr[28] = a[28] & bbit;
    assign ppr[29] = a[29] & bbit;
    assign ppr[30] = a[30] & bbit;
    assign ppr[31] = a[31] & bbit;
endmodule

module partial_products32(input [31:0] a, input [31:0] b, output [1023:0] pp);
    // define a input 80.160.255
    // define b input 80.200.255
    // define pp output 120.255.160
    // one row instance per b bit: pp[i*32+j] = a[j] & b[i], as before
    partial_products32_row u_row0(.a(a), .bbit(b[0]), .ppr(pp[31:0]));
    partial_products32_row u_row1(.a(a), .bbit(b[1]), .ppr(pp[63:32]));
    partial_products32_row u_row2(.a(a), .bbit(b[2]), .ppr(pp[95:64]));
    partial_products32_row u_row3(.a(a), .bbit(b[3]), .ppr(pp[127:96]));
    partial_products32_row u_row4(.a(a), .bbit(b[4]), .ppr(pp[159:128]));
    partial_products32_row u_row5(.a(a), .bbit(b[5]), .ppr(pp[191:160]));
    partial_products32_row u_row6(.a(a), .bbit(b[6]), .ppr(pp[223:192]));
    partial_products32_row u_row7(.a(a), .bbit(b[7]), .ppr(pp[255:224]));
    partial_products32_row u_row8(.a(a), .bbit(b[8]), .ppr(pp[287:256]));
    partial_products32_row u_row9(.a(a), .bbit(b[9]), .ppr(pp[319:288]));
    partial_products32_row u_row10(.a(a), .bbit(b[10]), .ppr(pp[351:320]));
    partial_products32_row u_row11(.a(a), .bbit(b[11]), .ppr(pp[383:352]));
    partial_products32_row u_row12(.a(a), .bbit(b[12]), .ppr(pp[415:384]));
    partial_products32_row u_row13(.a(a), .bbit(b[13]), .ppr(pp[447:416]));
    partial_products32_row u_row14(.a(a), .bbit(b[14]), .ppr(pp[479:448]));
    partial_products32_row u_row15(.a(a), .bbit(b[15]), .ppr(pp[511:480]));
    partial_products32_row u_row16(.a(a), .bbit(b[16]), .ppr(pp[543:512]));
    partial_products32_row u_row17(.a(a), .bbit(b[17]), .ppr(pp[575:544]));
    partial_products32_row u_row18(.a(a), .bbit(b[18]), .ppr(pp[607:576]));
    partial_products32_row u_row19(.a(a), .bbit(b[19]), .ppr(pp[639:608]));
    partial_products32_row u_row20(.a(a), .bbit(b[20]), .ppr(pp[671:640]));
    partial_products32_row u_row21(.a(a), .bbit(b[21]), .ppr(pp[703:672]));
    partial_products32_row u_row22(.a(a), .bbit(b[22]), .ppr(pp[735:704]));
    partial_products32_row u_row23(.a(a), .bbit(b[23]), .ppr(pp[767:736]));
    partial_products32_row u_row24(.a(a), .bbit(b[24]), .ppr(pp[799:768]));
    partial_products32_row u_row25(.a(a), .bbit(b[25]), .ppr(pp[831:800]));
    partial_products32_row u_row26(.a(a), .bbit(b[26]), .ppr(pp[863:832]));
    partial_products32_row u_row27(.a(a), .bbit(b[27]), .ppr(pp[895:864]));
    partial_products32_row u_row28(.a(a), .bbit(b[28]), .ppr(pp[927:896]));
    partial_products32_row u_row29(.a(a), .bbit(b[29]), .ppr(pp[959:928]));
    partial_products32_row u_row30(.a(a), .bbit(b[30]), .ppr(pp[991:960]));
    partial_products32_row u_row31(.a(a), .bbit(b[31]), .ppr(pp[1023:992]));
endmodule


