// =====================================================================
//  clock_divider8.v
//  Clock divider by 8.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module clock_divider8(input clk, input rst, output clk_out);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define clk_out output 120.255.160
    reg [2:0] cnt;
    always @(posedge clk) if (rst) cnt<=0; else cnt<=cnt+1'b1;
    assign clk_out = cnt[2];
endmodule


