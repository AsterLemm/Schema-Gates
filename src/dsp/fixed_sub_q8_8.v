// =====================================================================
//  fixed_sub_q8_8.v
//  Q8.8 fixed-point subtract (16-bit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fixed_sub_q8_8(input signed [15:0] a, input signed [15:0] b, output signed [15:0] y, output ovf);
    // define a input 80.160.255   // define b input 80.200.255   // define y output 120.255.160
    wire signed [16:0] s = a - b;
    assign y = s[15:0];
    assign ovf = (a[15]!=b[15]) && (y[15]!=a[15]);
endmodule


