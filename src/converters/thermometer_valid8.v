// =====================================================================
//  thermometer_valid8.v
//  8-bit thermometer-code validity check.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module thermometer_valid8(input [7:0] a, output valid);
    // define a input 80.160.255   // define valid output 255.255.255
    // valid thermometer = contiguous 1s from LSB: a[i] >= a[i+1]
    assign valid = &{ (a[0] | ~a[1]), (a[1] | ~a[2]), (a[2] | ~a[3]), (a[3] | ~a[4]), (a[4] | ~a[5]), (a[5] | ~a[6]), (a[6] | ~a[7]) };
endmodule


