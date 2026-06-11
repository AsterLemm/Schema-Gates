// =====================================================================
//  lut4_4.v
//  4-input 4-bit lookup table.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module lut4_4(input [3:0] addr, output [3:0] y);
    // define addr input 80.160.255   // define y output 120.255.160
    // 4-input 4-bit table (64 bits <= 2048 ROM cap).
    reg [3:0] mem [0:15];
    integer i; initial for (i=0;i<16;i=i+1) mem[i]=i[3:0];   // identity init (edit as needed)
    assign y = mem[addr];
endmodule


