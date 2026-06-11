// =====================================================================
//  signmag_to_twos4.v
//  4-bit sign-magnitude->two's complement.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module signmag_to_twos4(input [3:0] a, output [3:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    wire [2:0] mag = a[2:0];
    assign y = a[3] ? ((~{1'b0,mag}) + 1'b1) : {1'b0,mag};
endmodule


