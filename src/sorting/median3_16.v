// =====================================================================
//  median3_16.v
//  16-bit median-of-3.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module median3_16(input [15:0] a, input [15:0] b, input [15:0] c, output [15:0] med);
    // define a input 80.160.255   // define b input 80.200.255   // define c input 80.200.255   // define med output 120.255.160
    wire [15:0] mx = (a>b)?a:b;
    wire [15:0] mn = (a<b)?a:b;
    assign med = (c>mx)?mx : (c<mn)?mn : c;
endmodule


