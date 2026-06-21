// =====================================================================
//  bcd_to_7seg.v
//  BCD digit (0-9) to 7-segment decoder (blank if >9).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_to_7seg(input [3:0] a, output reg [6:0] seg);
    // define a input 80.160.255
    // define seg output 120.255.160
    always @(*) case(a)
        4'd0: seg=7'b0111111; 4'd1: seg=7'b0000110; 4'd2: seg=7'b1011011; 4'd3: seg=7'b1001111;
        4'd4: seg=7'b1100110; 4'd5: seg=7'b1101101; 4'd6: seg=7'b1111101; 4'd7: seg=7'b0000111;
        4'd8: seg=7'b1111111; 4'd9: seg=7'b1101111; default: seg=7'b0000000;
    endcase
endmodule


