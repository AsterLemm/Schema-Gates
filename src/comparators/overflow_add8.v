// =====================================================================
//  overflow_add8.v
//  Signed add overflow, 8-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module overflow_add8(input [7:0] a, input [7:0] b, output ovf);
    // define a input 80.160.255   // define b input 80.200.255   // define ovf output 255.120.120
    wire [7:0] s = a + b;
    assign ovf = (a[7] == b[7]) & (s[7] != a[7]);
endmodule


