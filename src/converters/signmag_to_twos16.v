// =====================================================================
//  signmag_to_twos16.v
//  16-bit sign-magnitude->two's complement.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module signmag_to_twos16(input [15:0] a, output [15:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    wire [14:0] mag = a[14:0];
    assign y = a[15] ? ((~{1'b0,mag}) + 1'b1) : {1'b0,mag};
endmodule


