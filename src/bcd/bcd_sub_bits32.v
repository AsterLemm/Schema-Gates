// =====================================================================
//  bcd_sub_bits32.v
//  32-bit (8-digit) BCD subtractor.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_sub_bits32(input [31:0] a, input [31:0] b, input bin, output [31:0] diff, output bout);
    // define a input 80.160.255   // define b input 80.200.255   // define bin input 255.230.80
    // define diff output 120.255.160   // define bout output 255.120.120
    wire [8:0] db; assign db[0]=bin;
    wire [4:0] raw0 = a[3:0] - b[3:0] - db[0];
    wire borrow0 = raw0[4];
    wire [4:0] adj0 = borrow0 ? (raw0 - 5'd6) : raw0;
    assign diff[3:0] = adj0[3:0];
    assign db[1] = borrow0;
    wire [4:0] raw1 = a[7:4] - b[7:4] - db[1];
    wire borrow1 = raw1[4];
    wire [4:0] adj1 = borrow1 ? (raw1 - 5'd6) : raw1;
    assign diff[7:4] = adj1[3:0];
    assign db[2] = borrow1;
    wire [4:0] raw2 = a[11:8] - b[11:8] - db[2];
    wire borrow2 = raw2[4];
    wire [4:0] adj2 = borrow2 ? (raw2 - 5'd6) : raw2;
    assign diff[11:8] = adj2[3:0];
    assign db[3] = borrow2;
    wire [4:0] raw3 = a[15:12] - b[15:12] - db[3];
    wire borrow3 = raw3[4];
    wire [4:0] adj3 = borrow3 ? (raw3 - 5'd6) : raw3;
    assign diff[15:12] = adj3[3:0];
    assign db[4] = borrow3;
    wire [4:0] raw4 = a[19:16] - b[19:16] - db[4];
    wire borrow4 = raw4[4];
    wire [4:0] adj4 = borrow4 ? (raw4 - 5'd6) : raw4;
    assign diff[19:16] = adj4[3:0];
    assign db[5] = borrow4;
    wire [4:0] raw5 = a[23:20] - b[23:20] - db[5];
    wire borrow5 = raw5[4];
    wire [4:0] adj5 = borrow5 ? (raw5 - 5'd6) : raw5;
    assign diff[23:20] = adj5[3:0];
    assign db[6] = borrow5;
    wire [4:0] raw6 = a[27:24] - b[27:24] - db[6];
    wire borrow6 = raw6[4];
    wire [4:0] adj6 = borrow6 ? (raw6 - 5'd6) : raw6;
    assign diff[27:24] = adj6[3:0];
    assign db[7] = borrow6;
    wire [4:0] raw7 = a[31:28] - b[31:28] - db[7];
    wire borrow7 = raw7[4];
    wire [4:0] adj7 = borrow7 ? (raw7 - 5'd6) : raw7;
    assign diff[31:28] = adj7[3:0];
    assign db[8] = borrow7;
    assign bout = db[8];
endmodule


