// =====================================================================
//  onehot_valid4.v
//  One-hot validity (exactly-one-bit) 4-bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module onehot_valid4(input [3:0] a, output valid);
    // define a input 80.160.255
    // define valid output 255.255.255
    wire any  = |a;
    reg has_lower;
    reg multi;
    integer k;
    always @(*) begin
        has_lower = 1'b0; multi = 1'b0;
        for (k=0;k<4;k=k+1) begin
            if (a[k] && has_lower) multi = 1'b1;
            if (a[k]) has_lower = 1'b1;
        end
    end
    assign valid = any & ~multi;
endmodule


