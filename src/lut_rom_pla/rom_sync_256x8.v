// =====================================================================
//  rom_sync_256x8.v
//  Synchronous ROM, 256x8 bits.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rom_sync_256x8(input clk, input [7:0] addr, output reg [7:0] data);
    // define clk input 255.230.80
    // define addr input 80.160.255
    // define data output 120.255.160
    // Synchronous ROM 256x8 = 2048 bits (cap 2048).
    reg [7:0] mem [0:255];
    integer i; initial for (i=0;i<256;i=i+1) mem[i]=i[7:0];
    always @(posedge clk) data <= mem[addr];
endmodule


