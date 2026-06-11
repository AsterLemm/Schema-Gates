// =====================================================================
//  set_bit4.v
//  4-bit set-bit at pos.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module set_bit4(input [3:0] a, input [1:0] pos, output [3:0] y);
    // define a input 80.160.255   // define pos input 200.120.255   // define y output 120.255.160
    assign y = a | ({4'b1} << pos);
endmodule


