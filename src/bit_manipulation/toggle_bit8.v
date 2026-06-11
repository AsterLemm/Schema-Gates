// =====================================================================
//  toggle_bit8.v
//  8-bit toggle-bit at pos.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module toggle_bit8(input [7:0] a, input [2:0] pos, output [7:0] y);
    // define a input 80.160.255   // define pos input 200.120.255   // define y output 120.255.160
    assign y = a ^ ({8'b1} << pos);
endmodule


