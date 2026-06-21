// =====================================================================
//  jkff.v
//  JK flip-flop.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module jkff(input clk, input j, input k, output reg q);
    always @(posedge clk) case({j,k}) 2'b01:q<=0;2'b10:q<=1;2'b11:q<=~q;default:; endcase
endmodule


