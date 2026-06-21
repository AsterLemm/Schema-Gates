// =====================================================================
//  signmag_to_twos32.v
//  32-bit sign-magnitude->two's complement.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module signmag_to_twos32(input [31:0] a, output [31:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    wire [30:0] mag = a[30:0];
    assign y = a[31] ? ((~{1'b0,mag}) + 1'b1) : {1'b0,mag};
endmodule


