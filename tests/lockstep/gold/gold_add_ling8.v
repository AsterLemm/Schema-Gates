// =====================================================================
//  add_ling8.v
//  8-bit Ling-style adder (transmit t=a|b, carry recurrence).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_add_ling8(input [7:0] a, input [7:0] b, input cin, output [7:0] sum, output cout);
    // define a input 80.160.255   // define b input 80.200.255
    // define cin input 255.230.80   // define sum output 120.255.160   // define cout output 255.120.120
    wire [7:0] p, g, t;
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
    wire [8:0] c; assign c[0]=cin;
    assign c[1] = g[0] | (t[0] & c[0]);
    assign c[2] = g[1] | (t[1] & c[1]);
    assign c[3] = g[2] | (t[2] & c[2]);
    assign c[4] = g[3] | (t[3] & c[3]);
    assign c[5] = g[4] | (t[4] & c[4]);
    assign c[6] = g[5] | (t[5] & c[5]);
    assign c[7] = g[6] | (t[6] & c[6]);
    assign c[8] = g[7] | (t[7] & c[7]);
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign sum[4] = p[4] ^ c[4];
    assign sum[5] = p[5] ^ c[5];
    assign sum[6] = p[6] ^ c[6];
    assign sum[7] = p[7] ^ c[7];
    assign cout = c[8];
endmodule


