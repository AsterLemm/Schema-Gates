// =====================================================================
//  fixed_saturate_q16_16.v
//  Q16.16 saturate wide accumulator to 32-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fixed_saturate_q16_16(input signed [35:0] a, output signed [31:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    wire signed [31:0] maxv = {1'b0,{31{1'b1}}};
    wire signed [31:0] minv = {1'b1,{31{1'b0}}};
    assign y = (a > maxv) ? maxv : (a < minv) ? minv : a[31:0];
endmodule


