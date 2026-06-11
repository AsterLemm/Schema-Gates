// =====================================================================
//  fixed_sub_q4_4.v
//  Q4.4 fixed-point subtract (8-bit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fixed_sub_q4_4(input signed [7:0] a, input signed [7:0] b, output signed [7:0] y, output ovf);
    // define a input 80.160.255   // define b input 80.200.255   // define y output 120.255.160
    wire signed [8:0] s = a - b;
    assign y = s[7:0];
    assign ovf = (a[7]!=b[7]) && (y[7]!=a[7]);
endmodule


