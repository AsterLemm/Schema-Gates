// =====================================================================
//  bit_reverse16.v
//  16-bit bit-reverse.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bit_reverse16(input [15:0] a, output [15:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y = {a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9], a[10], a[11], a[12], a[13], a[14], a[15]};
endmodule


