// =====================================================================
//  clock_divider4.v
//  Clock divider by 4.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module clock_divider4(input clk, input rst, output clk_out);
    // define clk input 255.230.80   // define rst input 255.80.80   // define clk_out output 120.255.160
    reg [1:0] cnt;
    always @(posedge clk) if (rst) cnt<=0; else cnt<=cnt+1'b1;
    assign clk_out = cnt[1];
endmodule


