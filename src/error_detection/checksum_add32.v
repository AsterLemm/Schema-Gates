// =====================================================================
//  checksum_add32.v
//  32-bit additive checksum step.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module checksum_add32(input [31:0] a, input [31:0] b, input [31:0] acc_in, output [31:0] acc_out, output carry);
    // define a input 80.160.255   // define b input 80.200.255   // define acc_out output 120.255.160
    wire [32:0] s = a + b + acc_in;
    assign acc_out = s[31:0]; assign carry = s[32];
endmodule


