// =====================================================================
//  decoder5to32.v
//  5-to-32 one-hot decoder.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module decoder5to32(input [4:0] a, output [31:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y[0] = (~a[0] & ~a[1] & ~a[2] & ~a[3] & ~a[4]);
    assign y[1] = (a[0] & ~a[1] & ~a[2] & ~a[3] & ~a[4]);
    assign y[2] = (~a[0] & a[1] & ~a[2] & ~a[3] & ~a[4]);
    assign y[3] = (a[0] & a[1] & ~a[2] & ~a[3] & ~a[4]);
    assign y[4] = (~a[0] & ~a[1] & a[2] & ~a[3] & ~a[4]);
    assign y[5] = (a[0] & ~a[1] & a[2] & ~a[3] & ~a[4]);
    assign y[6] = (~a[0] & a[1] & a[2] & ~a[3] & ~a[4]);
    assign y[7] = (a[0] & a[1] & a[2] & ~a[3] & ~a[4]);
    assign y[8] = (~a[0] & ~a[1] & ~a[2] & a[3] & ~a[4]);
    assign y[9] = (a[0] & ~a[1] & ~a[2] & a[3] & ~a[4]);
    assign y[10] = (~a[0] & a[1] & ~a[2] & a[3] & ~a[4]);
    assign y[11] = (a[0] & a[1] & ~a[2] & a[3] & ~a[4]);
    assign y[12] = (~a[0] & ~a[1] & a[2] & a[3] & ~a[4]);
    assign y[13] = (a[0] & ~a[1] & a[2] & a[3] & ~a[4]);
    assign y[14] = (~a[0] & a[1] & a[2] & a[3] & ~a[4]);
    assign y[15] = (a[0] & a[1] & a[2] & a[3] & ~a[4]);
    assign y[16] = (~a[0] & ~a[1] & ~a[2] & ~a[3] & a[4]);
    assign y[17] = (a[0] & ~a[1] & ~a[2] & ~a[3] & a[4]);
    assign y[18] = (~a[0] & a[1] & ~a[2] & ~a[3] & a[4]);
    assign y[19] = (a[0] & a[1] & ~a[2] & ~a[3] & a[4]);
    assign y[20] = (~a[0] & ~a[1] & a[2] & ~a[3] & a[4]);
    assign y[21] = (a[0] & ~a[1] & a[2] & ~a[3] & a[4]);
    assign y[22] = (~a[0] & a[1] & a[2] & ~a[3] & a[4]);
    assign y[23] = (a[0] & a[1] & a[2] & ~a[3] & a[4]);
    assign y[24] = (~a[0] & ~a[1] & ~a[2] & a[3] & a[4]);
    assign y[25] = (a[0] & ~a[1] & ~a[2] & a[3] & a[4]);
    assign y[26] = (~a[0] & a[1] & ~a[2] & a[3] & a[4]);
    assign y[27] = (a[0] & a[1] & ~a[2] & a[3] & a[4]);
    assign y[28] = (~a[0] & ~a[1] & a[2] & a[3] & a[4]);
    assign y[29] = (a[0] & ~a[1] & a[2] & a[3] & a[4]);
    assign y[30] = (~a[0] & a[1] & a[2] & a[3] & a[4]);
    assign y[31] = (a[0] & a[1] & a[2] & a[3] & a[4]);
endmodule


