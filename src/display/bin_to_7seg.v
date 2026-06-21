// =====================================================================
//  bin_to_7seg.v
//  4-bit hex to 7-segment decoder (active-high).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_7seg(input [3:0] a, output reg [6:0] seg);
    // define a input 80.160.255
    // define seg output 120.255.160
    // seg = {g,f,e,d,c,b,a}, active-high, hex 0-F
    always @(*) case(a)
        4'h0: seg=7'b0111111; 4'h1: seg=7'b0000110; 4'h2: seg=7'b1011011; 4'h3: seg=7'b1001111;
        4'h4: seg=7'b1100110; 4'h5: seg=7'b1101101; 4'h6: seg=7'b1111101; 4'h7: seg=7'b0000111;
        4'h8: seg=7'b1111111; 4'h9: seg=7'b1101111; 4'ha: seg=7'b1110111; 4'hb: seg=7'b1111100;
        4'hc: seg=7'b0111001; 4'hd: seg=7'b1011110; 4'he: seg=7'b1111001; 4'hf: seg=7'b1110001;
    endcase
endmodule


