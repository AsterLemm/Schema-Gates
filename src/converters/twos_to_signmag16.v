// =====================================================================
//  twos_to_signmag16.v
//  16-bit two's complement->sign-magnitude.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module twos_to_signmag16(input signed [15:0] a, output [15:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    wire [15:0] m = a[15] ? ((~a)+1'b1) : a;
    assign y = {a[15], m[14:0]};
endmodule


