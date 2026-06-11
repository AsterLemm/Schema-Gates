// =====================================================================
//  addsub_saturating_signed16.v
//  16-bit signed saturating add/sub (clamp to +max/-min).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module addsub_saturating_signed16(input signed [15:0] a, input signed [15:0] b, input sub, output signed [15:0] result);
    // define a input 80.160.255   // define b input 80.200.255   // define sub input 200.120.255   // define result output 120.255.160
    wire signed [16:0] ext = sub ? (a - b) : (a + b);
    wire signed [15:0] maxv = {1'b0,{15{1'b1}}};
    wire signed [15:0] minv = {1'b1,{15{1'b0}}};
    assign result = (ext > maxv) ? maxv : (ext < minv) ? minv : ext[15:0];
endmodule


