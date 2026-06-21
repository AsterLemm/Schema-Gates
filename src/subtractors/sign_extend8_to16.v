// =====================================================================
//  sign_extend8_to16.v
//  Sign-extend 8-bit to 16-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sign_extend8_to16(input [7:0] a, output [15:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y = {{8{a[7]}}, a};   // replicate sign bit
endmodule


