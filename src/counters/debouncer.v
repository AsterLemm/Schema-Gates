// =====================================================================
//  debouncer.v
//  Switch debouncer (counter-based).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module debouncer(input clk, input rst, input noisy, output reg clean);
    reg [15:0] cnt;
    always @(posedge clk) begin
        if (rst) begin cnt<=0; clean<=0; end
        else if (noisy==clean) cnt<=0;
        else begin cnt<=cnt+1'b1; if (&cnt) clean<=noisy; end
    end
endmodule


