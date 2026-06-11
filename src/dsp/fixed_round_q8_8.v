// =====================================================================
//  fixed_round_q8_8.v
//  Q8.8 round-to-nearest integer.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fixed_round_q8_8(input signed [15:0] a, output signed [8:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    // round to integer: add 0.5 (1<<(qf-1)) then truncate fractional bits
    wire signed [15:0] r = a + 16'sd128;
    assign y = r >>> 8;
endmodule


