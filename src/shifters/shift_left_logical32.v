// =====================================================================
//  shift_left_logical32.v
//  32-bit logical left shift.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module shift_left_logical32(input [31:0] a, input [4:0] sh, output [31:0] y);
    // define a input 80.160.255
    // define sh input 200.120.255
    // define y output 120.255.160
    assign y = a << sh;
endmodule


