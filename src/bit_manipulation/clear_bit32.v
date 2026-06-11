// =====================================================================
//  clear_bit32.v
//  32-bit clear-bit at pos.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module clear_bit32(input [31:0] a, input [4:0] pos, output [31:0] y);
    // define a input 80.160.255   // define pos input 200.120.255   // define y output 120.255.160
    assign y = a & ~({32'b1} << pos);
endmodule


