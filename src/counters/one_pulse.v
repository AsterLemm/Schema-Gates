// =====================================================================
//  one_pulse.v
//  Single-cycle pulse on rising trigger.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module one_pulse(input clk, input rst, input trig, output reg pulse);
    reg seen;
    always @(posedge clk) begin if (rst) begin seen<=0; pulse<=0; end
        else begin pulse <= trig & ~seen; seen <= trig; end end
endmodule


