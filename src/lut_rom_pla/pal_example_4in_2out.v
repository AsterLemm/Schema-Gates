// =====================================================================
//  pal_example_4in_2out.v
//  Example PAL: 4-input, 2-output.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module pal_example_4in_2out(input [3:0] in, output [1:0] out);
    // define in input 80.160.255   // define out output 120.255.160
    // PAL: fixed OR-plane, programmable AND-plane.
    wire p0 = in[0] & in[1] & ~in[2];
    wire p1 = in[2] & in[3];
    wire p2 = ~in[0] & ~in[1];
    assign out[0] = p0 | p1;
    assign out[1] = p1 | p2;
endmodule


