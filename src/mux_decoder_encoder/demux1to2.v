// =====================================================================
//  demux1to2.v
//  1-to-2 demultiplexer (routes d to selected line).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module demux1to2(input d, input [0:0] sel, output [1:0] y);
    // define d input 80.160.255
    // define sel input 200.120.255
    // define y output 120.255.160
    assign y[0] = d & (~sel[0]);
    assign y[1] = d & (sel[0]);
endmodule


