// =====================================================================
//  byte_swap32.v
//  32-bit byte swap (endianness reverse).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module byte_swap32(input [31:0] a, output [31:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y = {a[7:0], a[15:8], a[23:16], a[31:24]};
endmodule


