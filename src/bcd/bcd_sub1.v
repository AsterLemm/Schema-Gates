// =====================================================================
//  bcd_sub1.v
//  1-digit BCD subtractor (-6 decimal correction).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_sub1(input [3:0] a, input [3:0] b, input bin, output [3:0] diff, output bout);
    // define a input 80.160.255   // define b input 80.200.255   // define bin input 255.230.80
    // define diff output 120.255.160   // define bout output 255.120.120
    wire [1:0] db; assign db[0]=bin;
    wire [4:0] raw0 = a[3:0] - b[3:0] - db[0];
    wire borrow0 = raw0[4];
    wire [4:0] adj0 = borrow0 ? (raw0 - 5'd6) : raw0;
    assign diff[3:0] = adj0[3:0];
    assign db[1] = borrow0;
    assign bout = db[1];
endmodule


