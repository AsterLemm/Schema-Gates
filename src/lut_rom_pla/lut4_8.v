// =====================================================================
//  lut4_8.v
//  4-input 8-bit lookup table.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module lut4_8(input [3:0] addr, output [7:0] y);
    // define addr input 80.160.255   // define y output 120.255.160
    // 4-input 8-bit table (128 bits <= 2048 ROM cap).
    reg [7:0] mem [0:15];
    integer i; initial for (i=0;i<16;i=i+1) mem[i]=i[7:0];   // identity init (edit as needed)
    assign y = mem[addr];
endmodule


