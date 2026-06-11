// =====================================================================
//  overflow_add4.v
//  Signed add overflow, 4-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module overflow_add4(input [3:0] a, input [3:0] b, output ovf);
    // define a input 80.160.255   // define b input 80.200.255   // define ovf output 255.120.120
    wire [3:0] s = a + b;
    assign ovf = (a[3] == b[3]) & (s[3] != a[3]);
endmodule


