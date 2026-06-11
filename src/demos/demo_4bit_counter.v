// =====================================================================
//  demo_4bit_counter.v
//  Demo: 4-bit counter driving a 7-segment display.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module demo_4bit_counter(input clk, input rst, output reg [3:0] count, output [6:0] seg);
    // define clk input 255.230.80   // define rst input 255.80.80   // define count output 120.255.160   // define seg output 120.255.160
    always @(posedge clk) if (rst) count<=4'b0; else count<=count+1'b1;
    reg [6:0] s;
    always @(*) case(count)
        4'h0:s=7'b0111111;4'h1:s=7'b0000110;4'h2:s=7'b1011011;4'h3:s=7'b1001111;
        4'h4:s=7'b1100110;4'h5:s=7'b1101101;4'h6:s=7'b1111101;4'h7:s=7'b0000111;
        4'h8:s=7'b1111111;4'h9:s=7'b1101111;4'ha:s=7'b1110111;4'hb:s=7'b1111100;
        4'hc:s=7'b0111001;4'hd:s=7'b1011110;4'he:s=7'b1111001;4'hf:s=7'b1110001;
    endcase
    assign seg=s;
endmodule


