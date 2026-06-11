// =====================================================================
//  parity_check16.v
//  16-bit even-parity checker.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module parity_check16(input [15:0] a, input p, output error);
    // define a input 80.160.255   // define p input 255.230.80   // define error output 255.120.120
    assign error = (^a) ^ p;   // even-parity check
endmodule


