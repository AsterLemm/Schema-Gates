// =====================================================================
//  last_one_index8.v
//  8-bit index of last (highest) set bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module last_one_index8(input [7:0] a, output [3:0] idx, output valid);
    // define a input 80.160.255   // define idx output 120.255.160   // define valid output 255.255.255
    integer k; reg [3:0] r;
    always @(*) begin r=0;
        for (k=0;k<8;k=k+1) if (a[k]) r=k[3:0];
    end
    assign idx=r; assign valid=|a;
endmodule


