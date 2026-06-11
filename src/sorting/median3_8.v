// =====================================================================
//  median3_8.v
//  8-bit median-of-3.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module median3_8(input [7:0] a, input [7:0] b, input [7:0] c, output [7:0] med);
    // define a input 80.160.255   // define b input 80.200.255   // define c input 80.200.255   // define med output 120.255.160
    wire [7:0] mx = (a>b)?a:b;
    wire [7:0] mn = (a<b)?a:b;
    assign med = (c>mx)?mx : (c<mn)?mn : c;
endmodule


