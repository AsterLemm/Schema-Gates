// =====================================================================
//  program_counter16.v
//  16-bit program counter (inc/load/reset).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module program_counter16(input clk, input rst, input en, input load, input [15:0] addr, output reg [15:0] pc);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define en input 255.180.80
    // define addr input 80.160.255
    // define pc output 120.255.160
    always @(posedge clk) if (rst) pc<=16'b0; else if (load) pc<=addr; else if (en) pc<=pc+1'b1;
endmodule


