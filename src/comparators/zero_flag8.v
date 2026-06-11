// =====================================================================
//  zero_flag8.v
//  Zero flag, 8-bit (result==0).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module zero_flag8(input [7:0] a, output zero);
    // define a input 80.160.255   // define zero output 255.255.255
    assign zero = ~(|a);
endmodule


