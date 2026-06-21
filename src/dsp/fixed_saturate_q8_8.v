// =====================================================================
//  fixed_saturate_q8_8.v
//  Q8.8 saturate wide accumulator to 16-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fixed_saturate_q8_8(input signed [19:0] a, output signed [15:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    wire signed [15:0] maxv = {1'b0,{15{1'b1}}};
    wire signed [15:0] minv = {1'b1,{15{1'b0}}};
    assign y = (a > maxv) ? maxv : (a < minv) ? minv : a[15:0];
endmodule


