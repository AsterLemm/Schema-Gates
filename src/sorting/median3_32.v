// =====================================================================
//  median3_32.v
//  32-bit median-of-3.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module median3_32(input [31:0] a, input [31:0] b, input [31:0] c, output [31:0] med);
    // define a input 80.160.255   // define b input 80.200.255   // define c input 80.200.255   // define med output 120.255.160
    wire [31:0] mx = (a>b)?a:b;
    wire [31:0] mn = (a<b)?a:b;
    assign med = (c>mx)?mx : (c<mn)?mn : c;
endmodule


