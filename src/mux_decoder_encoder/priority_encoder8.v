// =====================================================================
//  priority_encoder8.v
//  Priority encoder (8->index of highest set bit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module priority_encoder8(input [7:0] a, output [2:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    integer k;
    reg [2:0] idx;
    always @(*) begin
        idx = 0;
        for (k=0; k<8; k=k+1) if (a[k]) idx = k[2:0];
    end
    assign y = idx;
endmodule


