// =====================================================================
//  bit_reverse8.v
//  8-bit bit-reverse.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bit_reverse8(input [7:0] a, output [7:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y = {a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7]};
endmodule


