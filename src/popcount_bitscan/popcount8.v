// =====================================================================
//  popcount8.v
//  8-bit population count (number of 1s).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module popcount8(input [7:0] a, output [3:0] count);
    // define a input 80.160.255   // define count output 120.255.160
    assign count = a[0]+a[1]+a[2]+a[3]+a[4]+a[5]+a[6]+a[7];
endmodule


