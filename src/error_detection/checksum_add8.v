// =====================================================================
//  checksum_add8.v
//  8-bit additive checksum step.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module checksum_add8(input [7:0] a, input [7:0] b, input [7:0] acc_in, output [7:0] acc_out, output carry);
    // define a input 80.160.255   // define b input 80.200.255   // define acc_out output 120.255.160
    wire [8:0] s = a + b + acc_in;
    assign acc_out = s[7:0]; assign carry = s[8];
endmodule


