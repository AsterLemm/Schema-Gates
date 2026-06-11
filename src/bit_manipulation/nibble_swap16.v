// =====================================================================
//  nibble_swap16.v
//  16-bit nibble swap (within each byte).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module nibble_swap16(input [15:0] a, output [15:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y = {a[15:12], a[11:8], a[7:4], a[3:0]};
endmodule


