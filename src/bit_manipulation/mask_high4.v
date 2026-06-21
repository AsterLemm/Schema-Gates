// =====================================================================
//  mask_high4.v
//  4-bit high-mask (n high bits set).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mask_high4(input [2:0] n, output [3:0] y);
    // define n input 200.120.255
    // define y output 120.255.160
    assign y = ~(({4'b1} << (4-n)) - 1'b1) ;
endmodule


