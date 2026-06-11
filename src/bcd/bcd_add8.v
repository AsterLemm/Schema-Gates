// =====================================================================
//  bcd_add8.v
//  8-digit BCD adder (+6 decimal correction).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_add8(input [31:0] a, input [31:0] b, input cin, output [31:0] sum, output cout);
    // define a input 80.160.255   // define b input 80.200.255   // define cin input 255.230.80
    // define sum output 120.255.160   // define cout output 255.120.120
    wire [8:0] dc; assign dc[0]=cin;   // decimal carries
    wire [4:0] raw0 = a[3:0] + b[3:0] + dc[0];
    wire corr0 = (raw0 > 9);
    wire [4:0] adj0 = corr0 ? (raw0 + 5'd6) : raw0;
    assign sum[3:0] = adj0[3:0];
    assign dc[1] = corr0;
    wire [4:0] raw1 = a[7:4] + b[7:4] + dc[1];
    wire corr1 = (raw1 > 9);
    wire [4:0] adj1 = corr1 ? (raw1 + 5'd6) : raw1;
    assign sum[7:4] = adj1[3:0];
    assign dc[2] = corr1;
    wire [4:0] raw2 = a[11:8] + b[11:8] + dc[2];
    wire corr2 = (raw2 > 9);
    wire [4:0] adj2 = corr2 ? (raw2 + 5'd6) : raw2;
    assign sum[11:8] = adj2[3:0];
    assign dc[3] = corr2;
    wire [4:0] raw3 = a[15:12] + b[15:12] + dc[3];
    wire corr3 = (raw3 > 9);
    wire [4:0] adj3 = corr3 ? (raw3 + 5'd6) : raw3;
    assign sum[15:12] = adj3[3:0];
    assign dc[4] = corr3;
    wire [4:0] raw4 = a[19:16] + b[19:16] + dc[4];
    wire corr4 = (raw4 > 9);
    wire [4:0] adj4 = corr4 ? (raw4 + 5'd6) : raw4;
    assign sum[19:16] = adj4[3:0];
    assign dc[5] = corr4;
    wire [4:0] raw5 = a[23:20] + b[23:20] + dc[5];
    wire corr5 = (raw5 > 9);
    wire [4:0] adj5 = corr5 ? (raw5 + 5'd6) : raw5;
    assign sum[23:20] = adj5[3:0];
    assign dc[6] = corr5;
    wire [4:0] raw6 = a[27:24] + b[27:24] + dc[6];
    wire corr6 = (raw6 > 9);
    wire [4:0] adj6 = corr6 ? (raw6 + 5'd6) : raw6;
    assign sum[27:24] = adj6[3:0];
    assign dc[7] = corr6;
    wire [4:0] raw7 = a[31:28] + b[31:28] + dc[7];
    wire corr7 = (raw7 > 9);
    wire [4:0] adj7 = corr7 ? (raw7 + 5'd6) : raw7;
    assign sum[31:28] = adj7[3:0];
    assign dc[8] = corr7;
    assign cout = dc[8];
endmodule


