// =====================================================================
//  add_ling4.v
//  4-bit Ling-style adder (transmit t=a|b, carry recurrence).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gold_add_ling4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define cin input 255.230.80
    // define sum output 120.255.160
    // define cout output 255.120.120
    wire [3:0] p, g, t;
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
    wire [4:0] c; assign c[0]=cin;
    assign c[1] = g[0] | (t[0] & c[0]);
    assign c[2] = g[1] | (t[1] & c[1]);
    assign c[3] = g[2] | (t[2] & c[2]);
    assign c[4] = g[3] | (t[3] & c[3]);
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    assign sum[3] = p[3] ^ c[3];
    assign cout = c[4];
endmodule


