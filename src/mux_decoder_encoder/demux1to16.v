// =====================================================================
//  demux1to16.v
//  1-to-16 demultiplexer (routes d to selected line).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module demux1to16(input d, input [3:0] sel, output [15:0] y);
    // define d input 80.160.255   // define sel input 200.120.255   // define y output 120.255.160
    assign y[0] = d & (~sel[0] & ~sel[1] & ~sel[2] & ~sel[3]);
    assign y[1] = d & (sel[0] & ~sel[1] & ~sel[2] & ~sel[3]);
    assign y[2] = d & (~sel[0] & sel[1] & ~sel[2] & ~sel[3]);
    assign y[3] = d & (sel[0] & sel[1] & ~sel[2] & ~sel[3]);
    assign y[4] = d & (~sel[0] & ~sel[1] & sel[2] & ~sel[3]);
    assign y[5] = d & (sel[0] & ~sel[1] & sel[2] & ~sel[3]);
    assign y[6] = d & (~sel[0] & sel[1] & sel[2] & ~sel[3]);
    assign y[7] = d & (sel[0] & sel[1] & sel[2] & ~sel[3]);
    assign y[8] = d & (~sel[0] & ~sel[1] & ~sel[2] & sel[3]);
    assign y[9] = d & (sel[0] & ~sel[1] & ~sel[2] & sel[3]);
    assign y[10] = d & (~sel[0] & sel[1] & ~sel[2] & sel[3]);
    assign y[11] = d & (sel[0] & sel[1] & ~sel[2] & sel[3]);
    assign y[12] = d & (~sel[0] & ~sel[1] & sel[2] & sel[3]);
    assign y[13] = d & (sel[0] & ~sel[1] & sel[2] & sel[3]);
    assign y[14] = d & (~sel[0] & sel[1] & sel[2] & sel[3]);
    assign y[15] = d & (sel[0] & sel[1] & sel[2] & sel[3]);
endmodule


