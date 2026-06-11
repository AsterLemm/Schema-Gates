// =====================================================================
//  counter_down32.v
//  32-bit down counter.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module counter_down32(input clk, input rst, input en, output reg [31:0] q);
    // define clk input 255.230.80   // define rst input 255.80.80   // define en input 255.180.80
    // define q output 120.255.160
    always @(posedge clk) if (rst) q<={32{1'b1}}; else if (en) q<=q-1'b1;
endmodule


