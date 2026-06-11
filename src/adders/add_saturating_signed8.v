// =====================================================================
//  add_saturating_signed8.v
//  8-bit signed saturating add (clamps to +max/-min on overflow).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_saturating_signed8(input signed [7:0] a, input signed [7:0] b, output signed [7:0] sum);
    // define a input 80.160.255   // define b input 80.200.255   // define sum output 120.255.160
    wire signed [8:0] ext = a + b;
    wire ovf = (a[7]==b[7]) && (ext[7]!=a[7]);
    assign sum = ovf ? (a[7] ? {1'b1,{7{1'b0}}} : {1'b0,{7{1'b1}}}) : ext[7:0];
endmodule


