// =====================================================================
//  dec4.v
//  4-bit decrementer (y=a-1), borrow chain.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module dec4(input [3:0] a, output [3:0] y, output bout);
    // define a input 80.160.255   // define y output 120.255.160   // define bout output 255.120.120
    wire [4:0] bw; assign bw[0]=1'b1;   // borrow chain, borrow-in=1 (subtract 1)
    assign y[0]    = a[0] ^ bw[0];
    assign bw[1] = (~a[0]) & bw[0];
    assign y[1]    = a[1] ^ bw[1];
    assign bw[2] = (~a[1]) & bw[1];
    assign y[2]    = a[2] ^ bw[2];
    assign bw[3] = (~a[2]) & bw[2];
    assign y[3]    = a[3] ^ bw[3];
    assign bw[4] = (~a[3]) & bw[3];
    assign bout=bw[4];
endmodule


