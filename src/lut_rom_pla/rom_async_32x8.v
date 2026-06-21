// =====================================================================
//  rom_async_32x8.v
//  Asynchronous ROM, 32x8 bits.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rom_async_32x8(input [4:0] addr, output [7:0] data);
    // define addr input 80.160.255
    // define data output 120.255.160
    // Asynchronous ROM 32x8 = 256 bits (cap 2048).
    reg [7:0] mem [0:31];
    integer i; initial for (i=0;i<32;i=i+1) mem[i]=i[7:0];
    assign data = mem[addr];
endmodule


