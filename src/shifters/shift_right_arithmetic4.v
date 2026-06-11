// =====================================================================
//  shift_right_arithmetic4.v
//  4-bit arithmetic right shift (sign-preserving).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module shift_right_arithmetic4(input signed [3:0] a, input [1:0] sh, output signed [3:0] y);
    // define a input 80.160.255   // define sh input 200.120.255   // define y output 120.255.160
    assign y = a >>> sh;
endmodule


