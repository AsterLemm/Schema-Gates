// =====================================================================
//  bcd_add2.v
//  2-digit BCD adder (+6 decimal correction).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_add2(input [7:0] a, input [7:0] b, input cin, output [7:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define cin input 255.230.80
    // define sum output 120.255.160
    // define cout output 255.120.120
    wire [2:0] dc; assign dc[0]=cin;   // decimal carries
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
    assign cout = dc[2];
endmodule


