// =====================================================================
//  demux1to32.v
//  1-to-32 demultiplexer (routes d to selected line).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module demux1to32(input d, input [4:0] sel, output [31:0] y);
    // define d input 80.160.255
    // define sel input 200.120.255
    // define y output 120.255.160
    assign y[0] = d & (~sel[0] & ~sel[1] & ~sel[2] & ~sel[3] & ~sel[4]);
    assign y[1] = d & (sel[0] & ~sel[1] & ~sel[2] & ~sel[3] & ~sel[4]);
    assign y[2] = d & (~sel[0] & sel[1] & ~sel[2] & ~sel[3] & ~sel[4]);
    assign y[3] = d & (sel[0] & sel[1] & ~sel[2] & ~sel[3] & ~sel[4]);
    assign y[4] = d & (~sel[0] & ~sel[1] & sel[2] & ~sel[3] & ~sel[4]);
    assign y[5] = d & (sel[0] & ~sel[1] & sel[2] & ~sel[3] & ~sel[4]);
    assign y[6] = d & (~sel[0] & sel[1] & sel[2] & ~sel[3] & ~sel[4]);
    assign y[7] = d & (sel[0] & sel[1] & sel[2] & ~sel[3] & ~sel[4]);
    assign y[8] = d & (~sel[0] & ~sel[1] & ~sel[2] & sel[3] & ~sel[4]);
    assign y[9] = d & (sel[0] & ~sel[1] & ~sel[2] & sel[3] & ~sel[4]);
    assign y[10] = d & (~sel[0] & sel[1] & ~sel[2] & sel[3] & ~sel[4]);
    assign y[11] = d & (sel[0] & sel[1] & ~sel[2] & sel[3] & ~sel[4]);
    assign y[12] = d & (~sel[0] & ~sel[1] & sel[2] & sel[3] & ~sel[4]);
    assign y[13] = d & (sel[0] & ~sel[1] & sel[2] & sel[3] & ~sel[4]);
    assign y[14] = d & (~sel[0] & sel[1] & sel[2] & sel[3] & ~sel[4]);
    assign y[15] = d & (sel[0] & sel[1] & sel[2] & sel[3] & ~sel[4]);
    assign y[16] = d & (~sel[0] & ~sel[1] & ~sel[2] & ~sel[3] & sel[4]);
    assign y[17] = d & (sel[0] & ~sel[1] & ~sel[2] & ~sel[3] & sel[4]);
    assign y[18] = d & (~sel[0] & sel[1] & ~sel[2] & ~sel[3] & sel[4]);
    assign y[19] = d & (sel[0] & sel[1] & ~sel[2] & ~sel[3] & sel[4]);
    assign y[20] = d & (~sel[0] & ~sel[1] & sel[2] & ~sel[3] & sel[4]);
    assign y[21] = d & (sel[0] & ~sel[1] & sel[2] & ~sel[3] & sel[4]);
    assign y[22] = d & (~sel[0] & sel[1] & sel[2] & ~sel[3] & sel[4]);
    assign y[23] = d & (sel[0] & sel[1] & sel[2] & ~sel[3] & sel[4]);
    assign y[24] = d & (~sel[0] & ~sel[1] & ~sel[2] & sel[3] & sel[4]);
    assign y[25] = d & (sel[0] & ~sel[1] & ~sel[2] & sel[3] & sel[4]);
    assign y[26] = d & (~sel[0] & sel[1] & ~sel[2] & sel[3] & sel[4]);
    assign y[27] = d & (sel[0] & sel[1] & ~sel[2] & sel[3] & sel[4]);
    assign y[28] = d & (~sel[0] & ~sel[1] & sel[2] & sel[3] & sel[4]);
    assign y[29] = d & (sel[0] & ~sel[1] & sel[2] & sel[3] & sel[4]);
    assign y[30] = d & (~sel[0] & sel[1] & sel[2] & sel[3] & sel[4]);
    assign y[31] = d & (sel[0] & sel[1] & sel[2] & sel[3] & sel[4]);
endmodule


