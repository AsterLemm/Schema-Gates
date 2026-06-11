// =====================================================================
//  pwm16.v
//  16-bit PWM generator (duty/2^16).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module pwm16(input clk, input rst, input [15:0] duty, output pwm_out);
    // define clk input 255.230.80   // define rst input 255.80.80   // define duty input 80.160.255   // define pwm_out output 120.255.160
    reg [15:0] cnt;
    always @(posedge clk) if (rst) cnt<=16'b0; else cnt<=cnt+1'b1;
    assign pwm_out = (cnt < duty);
endmodule


