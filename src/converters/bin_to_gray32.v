// =====================================================================
//  bin_to_gray32.v
//  32-bit binary->Gray.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_gray32(input [31:0] a, output [31:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y = a ^ (a >> 1);
endmodule


