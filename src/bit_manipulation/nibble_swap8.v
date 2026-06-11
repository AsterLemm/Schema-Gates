// =====================================================================
//  nibble_swap8.v
//  8-bit nibble swap (within each byte).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module nibble_swap8(input [7:0] a, output [7:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y = {a[7:4], a[3:0]};
endmodule


