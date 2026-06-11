// =====================================================================
//  rom_sync_128x16.v
//  Synchronous ROM, 128x16 bits.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rom_sync_128x16(input clk, input [6:0] addr, output reg [15:0] data);
    // define clk input 255.230.80   // define addr input 80.160.255   // define data output 120.255.160
    // Synchronous ROM 128x16 = 2048 bits (cap 2048).
    reg [15:0] mem [0:127];
    integer i; initial for (i=0;i<128;i=i+1) mem[i]=i[15:0];
    always @(posedge clk) data <= mem[addr];
endmodule


