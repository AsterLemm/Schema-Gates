// =====================================================================
//  priority_encoder16.v
//  Priority encoder (16->index of highest set bit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module priority_encoder16(input [15:0] a, output [3:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    integer k;
    reg [3:0] idx;
    always @(*) begin
        idx = 0;
        for (k=0; k<16; k=k+1) if (a[k]) idx = k[3:0];
    end
    assign y = idx;
endmodule


