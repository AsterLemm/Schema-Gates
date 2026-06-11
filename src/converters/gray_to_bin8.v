// =====================================================================
//  gray_to_bin8.v
//  8-bit Gray->binary (prefix XOR).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gray_to_bin8(input [7:0] a, output [7:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y[7] = a[7];
    assign y[6] = y[7] ^ a[6];
    assign y[5] = y[6] ^ a[5];
    assign y[4] = y[5] ^ a[4];
    assign y[3] = y[4] ^ a[3];
    assign y[2] = y[3] ^ a[2];
    assign y[1] = y[2] ^ a[1];
    assign y[0] = y[1] ^ a[0];
endmodule


