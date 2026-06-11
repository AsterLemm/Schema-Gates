// =====================================================================
//  trailing_one_count32.v
//  32-bit trailing-one count.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module trailing_one_count32(input [31:0] a, output [5:0] count);
    // define a input 80.160.255   // define count output 120.255.160
    integer k; reg [5:0] c; reg done;
    always @(*) begin c=0; done=0;
        for (k=0; k<32; k=k+1) begin if (!a[k]) done=1; if (!done) c=c+1'b1; end
    end
    assign count=c;
endmodule


