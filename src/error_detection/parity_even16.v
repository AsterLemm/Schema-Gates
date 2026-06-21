// =====================================================================
//  parity_even16.v
//  16-bit even-parity generator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module parity_even16(input [15:0] a, output p);
    // define a input 80.160.255
    // define p output 255.255.255
    assign p = ^a;   // even parity bit (1 if odd # of ones)
endmodule


