// =====================================================================
//  lut4_1.v
//  4-input 1-bit LUT (BITF_LUT directive).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module lut4_1(input [3:0] addr, output y);
    // define addr input 80.160.255   // define y output 120.255.160
    // BITF_LUT k=4 bits=1
    // 4-input 1-bit lookup table. INIT below is the truth table (LSB=addr 0).
    parameter [15:0] INIT = 16'h0;
    assign y = INIT[addr];
endmodule


