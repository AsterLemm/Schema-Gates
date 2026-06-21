// =====================================================================
//  hamming_decode_7_4.v
//  Hamming (7,4) decoder with single-error correction.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module hamming_decode_7_4(input [6:0] code, output [3:0] d, output [2:0] syndrome, output error);
    // define code input 80.160.255
    // define d output 120.255.160
    // define error output 255.120.120
    wire c1=code[0], c2=code[1], dd1=code[2], c4=code[3], dd2=code[4], dd3=code[5], dd4=code[6];
    wire s1 = c1 ^ dd1 ^ dd2 ^ dd4;
    wire s2 = c2 ^ dd1 ^ dd3 ^ dd4;
    wire s4 = c4 ^ dd2 ^ dd3 ^ dd4;
    wire [6:0] corr;
    wire [2:0] syn = {s4,s2,s1};
    assign corr = (syn==3'd0) ? code : (code ^ (7'b1 << (syn-1)));
    assign d = {corr[6],corr[5],corr[4],corr[2]};
    assign syndrome = syn;
    assign error = |syn;
endmodule


