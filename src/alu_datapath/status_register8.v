// =====================================================================
//  status_register8.v
//  8-bit status/flags register.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module status_register8(input clk, input rst, input load, input [7:0] flags_in, output reg [7:0] flags);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define load input 255.180.80
    // define flags_in input 80.160.255
    // define flags output 120.255.160
    always @(posedge clk) if (rst) flags<=8'b0; else if (load) flags<=flags_in;
endmodule


