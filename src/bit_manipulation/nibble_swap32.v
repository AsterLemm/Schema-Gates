// =====================================================================
//  nibble_swap32.v
//  32-bit nibble swap (within each byte).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module nibble_swap32(input [31:0] a, output [31:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y = {a[31:28], a[27:24], a[23:20], a[19:16], a[15:12], a[11:8], a[7:4], a[3:0]};
endmodule


