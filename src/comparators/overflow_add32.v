// =====================================================================
//  overflow_add32.v
//  Signed add overflow, 32-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module overflow_add32(input [31:0] a, input [31:0] b, output ovf);
    // define a input 80.160.255
    // define b input 80.200.255
    // define ovf output 255.120.120
    wire [31:0] s = a + b;
    assign ovf = (a[31] == b[31]) & (s[31] != a[31]);
endmodule


