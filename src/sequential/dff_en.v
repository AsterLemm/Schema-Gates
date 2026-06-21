// =====================================================================
//  dff_en.v
//  D flip-flop with enable.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module dff_en(input clk, input en, input d, output reg q);
    always @(posedge clk) if (en) q <= d;
endmodule


