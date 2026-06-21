// =====================================================================
//  twos_to_signmag32.v
//  32-bit two's complement->sign-magnitude.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module twos_to_signmag32(input signed [31:0] a, output [31:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    wire [31:0] m = a[31] ? ((~a)+1'b1) : a;
    assign y = {a[31], m[30:0]};
endmodule


