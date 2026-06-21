// =====================================================================
//  sipo32.v
//  32-bit serial-in parallel-out shift register.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sipo32(input clk, input sin, output [31:0] q);
    // define clk input 255.230.80
    // define sin input 80.160.255
    // define q output 120.255.160
    reg [31:0] sr;
    always @(posedge clk) sr <= {sr[30:0], sin};
    assign q = sr;
endmodule


