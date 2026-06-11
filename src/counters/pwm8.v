// =====================================================================
//  pwm8.v
//  8-bit PWM generator (duty/2^8).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module pwm8(input clk, input rst, input [7:0] duty, output pwm_out);
    // define clk input 255.230.80   // define rst input 255.80.80   // define duty input 80.160.255   // define pwm_out output 120.255.160
    reg [7:0] cnt;
    always @(posedge clk) if (rst) cnt<=8'b0; else cnt<=cnt+1'b1;
    assign pwm_out = (cnt < duty);
endmodule


