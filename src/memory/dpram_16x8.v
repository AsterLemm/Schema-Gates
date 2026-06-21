// =====================================================================
//  dpram_16x8.v
//  16x8 dual-port RAM.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module dpram_16x8(input clk, input we_a, input [3:0] addr_a, input [7:0] din_a, output reg [7:0] dout_a,
    input [3:0] addr_b, output reg [7:0] dout_b);
    // define clk input 255.230.80
    // define we_a input 255.180.80
    // True dual-port RAM 16x8 (128 bits).
    reg [7:0] mem [0:15];
    always @(posedge clk) begin if (we_a) mem[addr_a]<=din_a; dout_a<=mem[addr_a]; dout_b<=mem[addr_b]; end
endmodule


