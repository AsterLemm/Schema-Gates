// =====================================================================
//  compare_swap16.v
//  16-bit compare-and-swap cell (sorting primitive).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module compare_swap16(input [15:0] a, input [15:0] b, output [15:0] lo, output [15:0] hi);
    // define a input 80.160.255   // define b input 80.200.255   // define lo output 120.255.160   // define hi output 120.255.160
    assign lo = (a < b) ? a : b;
    assign hi = (a < b) ? b : a;
endmodule


