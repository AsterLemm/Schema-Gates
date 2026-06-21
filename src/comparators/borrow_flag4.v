// =====================================================================
//  borrow_flag4.v
//  Borrow flag for a-b-bin, 4-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module borrow_flag4(input [3:0] a, input [3:0] b, input bin, output borrow);
    // define a input 80.160.255
    // define b input 80.200.255
    // define bin input 255.230.80
    // define borrow output 255.120.120
    wire [4:0] ext;
    assign ext = {1'b0, a} - {1'b0, b} - bin;
    assign borrow = ext[4];   // underflow bit
endmodule


