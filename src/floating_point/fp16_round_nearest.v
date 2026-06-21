// =====================================================================
//  fp16_round_nearest.v
//  fp16 round-to-nearest-even unit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp16_round_nearest(input [12:0] mant_ext, output [9:0] mant);
    // define mant_ext input 80.160.255
    // define mant output 120.255.160
    // round-to-nearest-even on 3 guard bits
    wire [9:0] base = mant_ext[12:3];
    wire round_up = mant_ext[2] & (mant_ext[1] | mant_ext[0] | mant_ext[3]);
    assign mant = base + round_up;
endmodule


