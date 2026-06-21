// =====================================================================
//  ones_to_twos16.v
//  16-bit one's->two's complement.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module ones_to_twos16(input [15:0] a, output [15:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y = a[15] ? (a + 1'b1) : a;   // neg: add 1
endmodule


