// =====================================================================
//  bcd_sub2.v
//  2-digit BCD subtractor (-6 decimal correction).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_sub2(input [7:0] a, input [7:0] b, input bin, output [7:0] diff, output bout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define bin input 255.230.80
    // define diff output 120.255.160
    // define bout output 255.120.120
    wire [2:0] db; assign db[0]=bin;
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
    assign bout = db[2];
endmodule


