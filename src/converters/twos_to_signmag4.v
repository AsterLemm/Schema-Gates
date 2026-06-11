// =====================================================================
//  twos_to_signmag4.v
//  4-bit two's complement->sign-magnitude.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module twos_to_signmag4(input signed [3:0] a, output [3:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    wire [3:0] m = a[3] ? ((~a)+1'b1) : a;
    assign y = {a[3], m[2:0]};
endmodule


