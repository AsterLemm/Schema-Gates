// =====================================================================
//  instruction_register8.v
//  8-bit instruction register.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module instruction_register8(input clk, input rst, input load, input [7:0] din, output reg [7:0] ir);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define load input 255.180.80
    // define din input 80.160.255
    // define ir output 120.255.160
    always @(posedge clk) if (rst) ir<=8'b0; else if (load) ir<=din;
endmodule


