// =====================================================================
//  carry_flag16.v
//  Carry flag for a+b+cin, 16-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module carry_flag16(input [15:0] a, input [15:0] b, input cin, output carry);
    // define a input 80.160.255   // define b input 80.200.255   // define cin input 255.230.80   // define carry output 255.120.120
    wire [16:0] ext;
    assign ext = a + b + cin;
    assign carry = ext[16];
endmodule


