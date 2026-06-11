// =====================================================================
//  zero_extend16_to32.v
//  Zero-extend 16-bit to 32-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module zero_extend16_to32(input [15:0] a, output [31:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y = {{16{1'b0}}, a};   // pad with zeros
endmodule


