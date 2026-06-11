// =====================================================================
//  fixed_add_q16_16.v
//  Q16.16 fixed-point add (32-bit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fixed_add_q16_16(input signed [31:0] a, input signed [31:0] b, output signed [31:0] y, output ovf);
    // define a input 80.160.255   // define b input 80.200.255   // define y output 120.255.160
    wire signed [32:0] s = a + b;
    assign y = s[31:0];
    assign ovf = (a[31]==b[31]) && (y[31]!=a[31]);
endmodule


