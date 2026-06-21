// =====================================================================
//  bit_reverse4.v
//  4-bit bit-reverse.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bit_reverse4(input [3:0] a, output [3:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y = {a[0], a[1], a[2], a[3]};
endmodule


