// =====================================================================
//  zero_extend8_to16.v
//  Zero-extend 8-bit to 16-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module zero_extend8_to16(input [7:0] a, output [15:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y = {{8{1'b0}}, a};   // pad with zeros
endmodule


