// =====================================================================
//  add_ling16.v
//  16-bit Ling-style adder (transmit t=a|b, carry recurrence).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_ling16(input [15:0] a, input [15:0] b, input cin, output [15:0] sum, output cout);
    // define a input 80.160.255   // define b input 80.200.255
    // define cin input 255.230.80   // define sum output 120.255.160   // define cout output 255.120.120
    wire [15:0] p, g, t;
    assign p[0] = a[0] ^ b[0];
    assign g[0] = a[0] & b[0];
    assign t[0] = a[0] | b[0];
    assign p[1] = a[1] ^ b[1];
    assign g[1] = a[1] & b[1];
    assign t[1] = a[1] | b[1];
    assign p[2] = a[2] ^ b[2];
    assign g[2] = a[2] & b[2];
    assign t[2] = a[2] | b[2];
    assign p[3] = a[3] ^ b[3];
    assign g[3] = a[3] & b[3];
    assign t[3] = a[3] | b[3];
    assign p[4] = a[4] ^ b[4];
    assign g[4] = a[4] & b[4];
    assign t[4] = a[4] | b[4];
    assign p[5] = a[5] ^ b[5];
    assign g[5] = a[5] & b[5];
    assign t[5] = a[5] | b[5];
    assign p[6] = a[6] ^ b[6];
    assign g[6] = a[6] & b[6];
    assign t[6] = a[6] | b[6];
    assign p[7] = a[7] ^ b[7];
    assign g[7] = a[7] & b[7];
    assign t[7] = a[7] | b[7];
    assign p[8] = a[8] ^ b[8];
    assign g[8] = a[8] & b[8];
    assign t[8] = a[8] | b[8];
    assign p[9] = a[9] ^ b[9];
    assign g[9] = a[9] & b[9];
    assign t[9] = a[9] | b[9];
    assign p[10] = a[10] ^ b[10];
    assign g[10] = a[10] & b[10];
    assign t[10] = a[10] | b[10];
    assign p[11] = a[11] ^ b[11];
    assign g[11] = a[11] & b[11];
    assign t[11] = a[11] | b[11];
    assign p[12] = a[12] ^ b[12];
    assign g[12] = a[12] & b[12];
    assign t[12] = a[12] | b[12];
    assign p[13] = a[13] ^ b[13];
    assign g[13] = a[13] & b[13];
    assign t[13] = a[13] | b[13];
    assign p[14] = a[14] ^ b[14];
    assign g[14] = a[14] & b[14];
    assign t[14] = a[14] | b[14];
    assign p[15] = a[15] ^ b[15];
    assign g[15] = a[15] & b[15];
    assign t[15] = a[15] | b[15];
    wire [16:0] c; assign c[0]=cin;
    assign c[1] = g[0] | (t[0] & c[0]);
    assign c[2] = g[1] | (t[1] & c[1]);
    assign c[3] = g[2] | (t[2] & c[2]);
    assign c[4] = g[3] | (t[3] & c[3]);
    assign c[5] = g[4] | (t[4] & c[4]);
    assign c[6] = g[5] | (t[5] & c[5]);
    assign c[7] = g[6] | (t[6] & c[6]);
    assign c[8] = g[7] | (t[7] & c[7]);
    assign c[9] = g[8] | (t[8] & c[8]);
    assign c[10] = g[9] | (t[9] & c[9]);
    assign c[11] = g[10] | (t[10] & c[10]);
    assign c[12] = g[11] | (t[11] & c[11]);
    assign c[13] = g[12] | (t[12] & c[12]);
    assign c[14] = g[13] | (t[13] & c[13]);
    assign c[15] = g[14] | (t[14] & c[14]);
    assign c[16] = g[15] | (t[15] & c[15]);
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];
    assign sum[8] = p[8] ^ c[8];
    assign sum[9] = p[9] ^ c[9];
    assign sum[10] = p[10] ^ c[10];
    assign sum[11] = p[11] ^ c[11];
    assign sum[12] = p[12] ^ c[12];
    assign sum[13] = p[13] ^ c[13];
    assign sum[14] = p[14] ^ c[14];
    assign sum[15] = p[15] ^ c[15];
    assign cout = c[16];
endmodule


