// =====================================================================
//  twos_to_ones8.v
//  8-bit two's->one's complement.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module twos_to_ones8(input signed [7:0] a, output [7:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y = a[7] ? (a - 1'b1) : a;   // neg: subtract 1
endmodule


