// =====================================================================
//  parity_odd8.v
//  8-bit odd-parity generator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module parity_odd8(input [7:0] a, output p);
    // define a input 80.160.255   // define p output 255.255.255
    assign p = ~(^a);  // odd parity bit
endmodule


