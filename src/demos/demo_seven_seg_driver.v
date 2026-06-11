// =====================================================================
//  demo_seven_seg_driver.v
//  Demo: hex-to-7-segment driver with decimal point.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module demo_seven_seg_driver(input [3:0] value, input dp, output [7:0] seg);
    // define value input 80.160.255   // define dp input 255.230.80   // define seg output 120.255.160
    reg [6:0] base;
    always @(*) case(value)
        4'h0:base=7'b0111111;4'h1:base=7'b0000110;4'h2:base=7'b1011011;4'h3:base=7'b1001111;
        4'h4:base=7'b1100110;4'h5:base=7'b1101101;4'h6:base=7'b1111101;4'h7:base=7'b0000111;
        4'h8:base=7'b1111111;4'h9:base=7'b1101111;4'ha:base=7'b1110111;4'hb:base=7'b1111100;
        4'hc:base=7'b0111001;4'hd:base=7'b1011110;4'he:base=7'b1111001;4'hf:base=7'b1110001;
    endcase
    assign seg={dp,base};
endmodule


