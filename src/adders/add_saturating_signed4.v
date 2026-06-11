// =====================================================================
//  add_saturating_signed4.v
//  4-bit signed saturating add (clamps to +max/-min on overflow).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_saturating_signed4(input signed [3:0] a, input signed [3:0] b, output signed [3:0] sum);
    // define a input 80.160.255   // define b input 80.200.255   // define sum output 120.255.160
    wire signed [4:0] ext = a + b;
    wire ovf = (a[3]==b[3]) && (ext[3]!=a[3]);
    assign sum = ovf ? (a[3] ? {1'b1,{3{1'b0}}} : {1'b0,{3{1'b1}}}) : ext[3:0];
endmodule


