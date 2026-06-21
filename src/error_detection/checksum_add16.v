// =====================================================================
//  checksum_add16.v
//  16-bit additive checksum step.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module checksum_add16(input [15:0] a, input [15:0] b, input [15:0] acc_in, output [15:0] acc_out, output carry);
    // define a input 80.160.255
    // define b input 80.200.255
    // define acc_out output 120.255.160
    wire [16:0] s = a + b + acc_in;
    assign acc_out = s[15:0]; assign carry = s[16];
endmodule


