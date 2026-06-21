// =====================================================================
//  rom_sync_16x16.v
//  Synchronous ROM, 16x16 bits.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rom_sync_16x16(input clk, input [3:0] addr, output reg [15:0] data);
    // define clk input 255.230.80
    // define addr input 80.160.255
    // define data output 120.255.160
    // Synchronous ROM 16x16 = 256 bits (cap 2048).
    reg [15:0] mem [0:15];
    integer i; initial for (i=0;i<16;i=i+1) mem[i]=i[15:0];
    always @(posedge clk) data <= mem[addr];
endmodule


