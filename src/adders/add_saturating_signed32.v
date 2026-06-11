// =====================================================================
//  add_saturating_signed32.v
//  32-bit signed saturating add (clamps to +max/-min on overflow).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_saturating_signed32(input signed [31:0] a, input signed [31:0] b, output signed [31:0] sum);
    // define a input 80.160.255   // define b input 80.200.255   // define sum output 120.255.160
    wire signed [32:0] ext = a + b;
    wire ovf = (a[31]==b[31]) && (ext[31]!=a[31]);
    assign sum = ovf ? (a[31] ? {1'b1,{31{1'b0}}} : {1'b0,{31{1'b1}}}) : ext[31:0];
endmodule


