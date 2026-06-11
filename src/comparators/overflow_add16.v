// =====================================================================
//  overflow_add16.v
//  Signed add overflow, 16-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module overflow_add16(input [15:0] a, input [15:0] b, output ovf);
    // define a input 80.160.255   // define b input 80.200.255   // define ovf output 255.120.120
    wire [15:0] s = a + b;
    assign ovf = (a[15] == b[15]) & (s[15] != a[15]);
endmodule


