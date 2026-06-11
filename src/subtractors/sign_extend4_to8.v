// =====================================================================
//  sign_extend4_to8.v
//  Sign-extend 4-bit to 8-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sign_extend4_to8(input [3:0] a, output [7:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y = {{4{a[3]}}, a};   // replicate sign bit
endmodule


