// =====================================================================
//  bin_to_onehot16.v
//  Binary->one-hot (16 lines).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_onehot16(input [3:0] a, output [15:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y[0] = (~a[0] & ~a[1] & ~a[2] & ~a[3]);
    assign y[1] = (a[0] & ~a[1] & ~a[2] & ~a[3]);
    assign y[2] = (~a[0] & a[1] & ~a[2] & ~a[3]);
    assign y[3] = (a[0] & a[1] & ~a[2] & ~a[3]);
    assign y[4] = (~a[0] & ~a[1] & a[2] & ~a[3]);
    assign y[5] = (a[0] & ~a[1] & a[2] & ~a[3]);
    assign y[6] = (~a[0] & a[1] & a[2] & ~a[3]);
    assign y[7] = (a[0] & a[1] & a[2] & ~a[3]);
    assign y[8] = (~a[0] & ~a[1] & ~a[2] & a[3]);
    assign y[9] = (a[0] & ~a[1] & ~a[2] & a[3]);
    assign y[10] = (~a[0] & a[1] & ~a[2] & a[3]);
    assign y[11] = (a[0] & a[1] & ~a[2] & a[3]);
    assign y[12] = (~a[0] & ~a[1] & a[2] & a[3]);
    assign y[13] = (a[0] & ~a[1] & a[2] & a[3]);
    assign y[14] = (~a[0] & a[1] & a[2] & a[3]);
    assign y[15] = (a[0] & a[1] & a[2] & a[3]);
endmodule


