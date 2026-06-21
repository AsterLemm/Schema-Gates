// =====================================================================
//  add_saturating_signed16.v
//  16-bit signed saturating add (clamps to +max/-min on overflow).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_saturating_signed16(input signed [15:0] a, input signed [15:0] b, output signed [15:0] sum);
    // define a input 80.160.255
    // define b input 80.200.255
    // define sum output 120.255.160
    wire signed [16:0] ext = a + b;
    wire ovf = (a[15]==b[15]) && (ext[15]!=a[15]);
    assign sum = ovf ? (a[15] ? {1'b1,{15{1'b0}}} : {1'b0,{15{1'b1}}}) : ext[15:0];
endmodule


