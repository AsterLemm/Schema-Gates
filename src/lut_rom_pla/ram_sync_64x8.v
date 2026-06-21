// =====================================================================
//  ram_sync_64x8.v
//  Synchronous RAM, 64x8 bits.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module ram_sync_64x8(input clk, input we, input [5:0] addr, input [7:0] din, output reg [7:0] dout);
    // define clk input 255.230.80
    // define we input 255.180.80
    // define addr input 80.160.255
    // define din input 80.200.255
    // define dout output 120.255.160
    // Synchronous RAM 64x8 = 512 bits (cap 512).
    reg [7:0] mem [0:63];
    always @(posedge clk) begin if (we) mem[addr]<=din; dout<=mem[addr]; end
endmodule


