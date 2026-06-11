// =====================================================================
//  stack_pointer16.v
//  16-bit stack pointer (push dec / pop inc).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module stack_pointer16(input clk, input rst, input push, input pop, output reg [15:0] sp);
    // define clk input 255.230.80   // define rst input 255.80.80   // define push input 255.180.80
    // define sp output 120.255.160
    always @(posedge clk) if (rst) sp<={16{1'b1}}; else if (push) sp<=sp-1'b1; else if (pop) sp<=sp+1'b1;
endmodule


