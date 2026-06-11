// =====================================================================
//  hamming_encode_7_4.v
//  Hamming (7,4) encoder.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module hamming_encode_7_4(input [3:0] d, output [6:0] code);
    // define d input 80.160.255   // define code output 120.255.160
    // bits: p1 p2 d1 p4 d2 d3 d4  (positions 1..7)
    wire p1 = d[0]^d[1]^d[3];
    wire p2 = d[0]^d[2]^d[3];
    wire p4 = d[1]^d[2]^d[3];
    assign code = {d[3],d[2],d[1],p4,d[0],p2,p1};
endmodule


