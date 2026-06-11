// =====================================================================
//  fixed_saturate_q4_4.v
//  Q4.4 saturate wide accumulator to 8-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fixed_saturate_q4_4(input signed [11:0] a, output signed [7:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    wire signed [7:0] maxv = {1'b0,{7{1'b1}}};
    wire signed [7:0] minv = {1'b1,{7{1'b0}}};
    assign y = (a > maxv) ? maxv : (a < minv) ? minv : a[7:0];
endmodule


