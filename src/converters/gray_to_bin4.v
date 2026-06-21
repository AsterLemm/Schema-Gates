// =====================================================================
//  gray_to_bin4.v
//  4-bit Gray->binary (prefix XOR).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gray_to_bin4(input [3:0] a, output [3:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y[3] = a[3];
    assign y[2] = y[3] ^ a[2];
    assign y[1] = y[2] ^ a[1];
    assign y[0] = y[1] ^ a[0];
endmodule


