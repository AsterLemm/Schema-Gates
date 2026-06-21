// =====================================================================
//  demo_stopwatch.v
//  Demo: 2-digit BCD stopwatch (0-59 seconds).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module demo_stopwatch(input clk, input rst, input tick, output reg [3:0] ones, output reg [3:0] tens);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define tick input 255.180.80
    // define ones output 120.255.160
    // define tens output 120.255.160
    // Two-digit BCD seconds counter (0-59), advances on tick.
    always @(posedge clk) begin
        if (rst) begin ones<=0; tens<=0; end
        else if (tick) begin
            if (ones==4'd9) begin ones<=0;
                if (tens==4'd5) tens<=0; else tens<=tens+1'b1;
            end else ones<=ones+1'b1;
        end
    end
endmodule


