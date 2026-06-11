// =====================================================================
//  twos_to_signmag8.v
//  8-bit two's complement->sign-magnitude.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module twos_to_signmag8(input signed [7:0] a, output [7:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    wire [7:0] m = a[7] ? ((~a)+1'b1) : a;
    assign y = {a[7], m[6:0]};
endmodule


