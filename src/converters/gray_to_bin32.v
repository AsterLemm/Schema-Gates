// =====================================================================
//  gray_to_bin32.v
//  32-bit Gray->binary (prefix XOR).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module gray_to_bin32(input [31:0] a, output [31:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y[31] = a[31];
    assign y[30] = y[31] ^ a[30];
    assign y[29] = y[30] ^ a[29];
    assign y[28] = y[29] ^ a[28];
    assign y[27] = y[28] ^ a[27];
    assign y[26] = y[27] ^ a[26];
    assign y[25] = y[26] ^ a[25];
    assign y[24] = y[25] ^ a[24];
    assign y[23] = y[24] ^ a[23];
    assign y[22] = y[23] ^ a[22];
    assign y[21] = y[22] ^ a[21];
    assign y[20] = y[21] ^ a[20];
    assign y[19] = y[20] ^ a[19];
    assign y[18] = y[19] ^ a[18];
    assign y[17] = y[18] ^ a[17];
    assign y[16] = y[17] ^ a[16];
    assign y[15] = y[16] ^ a[15];
    assign y[14] = y[15] ^ a[14];
    assign y[13] = y[14] ^ a[13];
    assign y[12] = y[13] ^ a[12];
    assign y[11] = y[12] ^ a[11];
    assign y[10] = y[11] ^ a[10];
    assign y[9] = y[10] ^ a[9];
    assign y[8] = y[9] ^ a[8];
    assign y[7] = y[8] ^ a[7];
    assign y[6] = y[7] ^ a[6];
    assign y[5] = y[6] ^ a[5];
    assign y[4] = y[5] ^ a[4];
    assign y[3] = y[4] ^ a[3];
    assign y[2] = y[3] ^ a[2];
    assign y[1] = y[2] ^ a[1];
    assign y[0] = y[1] ^ a[0];
endmodule


