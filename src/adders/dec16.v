// =====================================================================
//  dec16.v
//  16-bit decrementer (y=a-1), borrow chain.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module dec16(input [15:0] a, output [15:0] y, output bout);
    // define a input 80.160.255
    // define y output 120.255.160
    // define bout output 255.120.120
    wire [16:0] bw; assign bw[0]=1'b1;   // borrow chain, borrow-in=1 (subtract 1)
    assign y[0]    = a[0] ^ bw[0];
    assign bw[1] = (~a[0]) & bw[0];
    assign y[1]    = a[1] ^ bw[1];
    assign bw[2] = (~a[1]) & bw[1];
    assign y[2]    = a[2] ^ bw[2];
    assign bw[3] = (~a[2]) & bw[2];
    assign y[3]    = a[3] ^ bw[3];
    assign bw[4] = (~a[3]) & bw[3];
    assign y[4]    = a[4] ^ bw[4];
    assign bw[5] = (~a[4]) & bw[4];
    assign y[5]    = a[5] ^ bw[5];
    assign bw[6] = (~a[5]) & bw[5];
    assign y[6]    = a[6] ^ bw[6];
    assign bw[7] = (~a[6]) & bw[6];
    assign y[7]    = a[7] ^ bw[7];
    assign bw[8] = (~a[7]) & bw[7];
    assign y[8]    = a[8] ^ bw[8];
    assign bw[9] = (~a[8]) & bw[8];
    assign y[9]    = a[9] ^ bw[9];
    assign bw[10] = (~a[9]) & bw[9];
    assign y[10]    = a[10] ^ bw[10];
    assign bw[11] = (~a[10]) & bw[10];
    assign y[11]    = a[11] ^ bw[11];
    assign bw[12] = (~a[11]) & bw[11];
    assign y[12]    = a[12] ^ bw[12];
    assign bw[13] = (~a[12]) & bw[12];
    assign y[13]    = a[13] ^ bw[13];
    assign bw[14] = (~a[13]) & bw[13];
    assign y[14]    = a[14] ^ bw[14];
    assign bw[15] = (~a[14]) & bw[14];
    assign y[15]    = a[15] ^ bw[15];
    assign bw[16] = (~a[15]) & bw[15];
    assign bout=bw[16];
endmodule


