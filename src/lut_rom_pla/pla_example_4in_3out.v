// =====================================================================
//  pla_example_4in_3out.v
//  Example PLA: 4-input, 3-output sum-of-products.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module pla_example_4in_3out(input [3:0] in, output [2:0] out);
    // define in input 80.160.255
    // define out output 120.255.160
    // Programmable Logic Array: AND-plane then OR-plane (sum of products).
    wire p0 =  in[0] & in[1];
    wire p1 =  in[2] & ~in[3];
    wire p2 = ~in[0] & in[3];
    wire p3 =  in[1] & in[2] & in[3];
    assign out[0] = p0 | p2;
    assign out[1] = p1 | p3;
    assign out[2] = p0 | p1 | p3;
endmodule


