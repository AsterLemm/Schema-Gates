// =====================================================================
//  siso16.v
//  16-bit serial-in serial-out shift register.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module siso16(input clk, input sin, output sout);
    // define clk input 255.230.80   // define sin input 80.160.255   // define sout output 120.255.160
    reg [15:0] sr;
    always @(posedge clk) sr <= {sr[14:0], sin};
    assign sout = sr[15];
endmodule


