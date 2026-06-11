// =====================================================================
//  zero_flag16.v
//  Zero flag, 16-bit (result==0).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module zero_flag16(input [15:0] a, output zero);
    // define a input 80.160.255   // define zero output 255.255.255
    assign zero = ~(|a);
endmodule


