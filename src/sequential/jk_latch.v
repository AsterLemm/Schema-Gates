// =====================================================================
//  jk_latch.v
//  JK latch.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module jk_latch(input j, input k, input en, output reg q);
    always @(*) if (en) case ({j,k}) 2'b01:q=1'b0; 2'b10:q=1'b1; 2'b11:q=~q; default:; endcase
endmodule


