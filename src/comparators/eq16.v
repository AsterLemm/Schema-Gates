// =====================================================================
//  eq16.v
//  Equality, 16-bit (eq=1 iff a==b).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module eq16(input [15:0] a, input [15:0] b, output eq);
    // define a input 80.160.255
    // define b input 80.200.255
    // define eq output 120.255.160
    assign eq  = (a == b);
endmodule


