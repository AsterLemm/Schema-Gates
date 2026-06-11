// =====================================================================
//  fixed_round_q16_16.v
//  Q16.16 round-to-nearest integer.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fixed_round_q16_16(input signed [31:0] a, output signed [16:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    // round to integer: add 0.5 (1<<(qf-1)) then truncate fractional bits
    wire signed [31:0] r = a + 32'sd32768;
    assign y = r >>> 16;
endmodule


