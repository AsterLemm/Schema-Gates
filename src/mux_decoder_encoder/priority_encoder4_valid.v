// =====================================================================
//  priority_encoder4_valid.v
//  Priority encoder w/ valid (4-bit; valid=|a).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module priority_encoder4_valid(input [3:0] a, output [1:0] y, output valid);
    // define a input 80.160.255
    // define y output 120.255.160
    // define valid output 255.255.255
    integer k;
    reg [1:0] idx;
    always @(*) begin
        idx = 0;
        for (k=0; k<4; k=k+1) if (a[k]) idx = k[1:0];
    end
    assign y = idx;
    assign valid = |a;
endmodule


