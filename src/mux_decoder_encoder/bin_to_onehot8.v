// =====================================================================
//  bin_to_onehot8.v
//  Binary->one-hot (8 lines).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_onehot8(input [2:0] a, output [7:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y[0] = (~a[0] & ~a[1] & ~a[2]);
    assign y[1] = (a[0] & ~a[1] & ~a[2]);
    assign y[2] = (~a[0] & a[1] & ~a[2]);
    assign y[3] = (a[0] & a[1] & ~a[2]);
    assign y[4] = (~a[0] & ~a[1] & a[2]);
    assign y[5] = (a[0] & ~a[1] & a[2]);
    assign y[6] = (~a[0] & a[1] & a[2]);
    assign y[7] = (a[0] & a[1] & a[2]);
endmodule


