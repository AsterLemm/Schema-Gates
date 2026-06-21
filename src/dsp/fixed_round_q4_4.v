// =====================================================================
//  fixed_round_q4_4.v
//  Q4.4 round-to-nearest integer.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fixed_round_q4_4(input signed [7:0] a, output signed [4:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    // round to integer: add 0.5 (1<<(qf-1)) then truncate fractional bits
    wire signed [7:0] r = a + 8'sd8;
    assign y = r >>> 4;
endmodule


