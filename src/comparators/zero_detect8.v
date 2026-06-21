// =====================================================================
//  zero_detect8.v
//  Zero detect, 8-bit (1 iff a==0).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module zero_detect8(input [7:0] a, output y);
    // define a input 80.160.255
    // define y output 255.255.255
    assign y = ~(|a);
endmodule


