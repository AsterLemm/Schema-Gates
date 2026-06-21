// =====================================================================
//  lut3_1.v
//  3-input 1-bit LUT (BITF_LUT directive).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module lut3_1(input [2:0] addr, output y);
    // define addr input 80.160.255
    // define y output 120.255.160
    // BITF_LUT k=3 bits=1
    // 3-input 1-bit lookup table. INIT below is the truth table (LSB=addr 0).
    parameter [7:0] INIT = 8'h0;
    assign y = INIT[addr];
endmodule


