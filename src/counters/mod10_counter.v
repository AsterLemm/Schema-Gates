// =====================================================================
//  mod10_counter.v
//  Modulo-10 counter (0..9), tc at terminal count.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mod10_counter(input clk, input rst, input en, output reg [3:0] q, output tc);
    // define clk input 255.230.80   // define rst input 255.80.80   // define en input 255.180.80
    // define q output 120.255.160   // define tc output 255.255.255
    assign tc = (q == 9);
    always @(posedge clk) if (rst) q<=4'b0; else if (en) q <= tc ? 4'b0 : q+1'b1;
endmodule


