// =====================================================================
//  thermometer_to_bin16.v
//  16-bit thermometer->binary (popcount).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module thermometer_to_bin16(input [15:0] a, output [4:0] n);
    // define a input 80.160.255
    // define n output 120.255.160
    assign n = a[0]+a[1]+a[2]+a[3]+a[4]+a[5]+a[6]+a[7]+a[8]+a[9]+a[10]+a[11]+a[12]+a[13]+a[14]+a[15];
endmodule


