// =====================================================================
//  overflow_sub16.v
//  Signed sub overflow, 16-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module overflow_sub16(input [15:0] a, input [15:0] b, output ovf);
    // define a input 80.160.255
    // define b input 80.200.255
    // define ovf output 255.120.120
    wire [15:0] d = a - b;
    assign ovf = (a[15] != b[15]) & (d[15] != a[15]);
endmodule


