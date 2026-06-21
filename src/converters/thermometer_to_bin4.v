// =====================================================================
//  thermometer_to_bin4.v
//  4-bit thermometer->binary (popcount).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module thermometer_to_bin4(input [3:0] a, output [2:0] n);
    // define a input 80.160.255
    // define n output 120.255.160
    assign n = a[0]+a[1]+a[2]+a[3];
endmodule


