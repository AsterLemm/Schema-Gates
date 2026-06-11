// =====================================================================
//  last_one_index4.v
//  4-bit index of last (highest) set bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module last_one_index4(input [3:0] a, output [2:0] idx, output valid);
    // define a input 80.160.255   // define idx output 120.255.160   // define valid output 255.255.255
    integer k; reg [2:0] r;
    always @(*) begin r=0;
        for (k=0;k<4;k=k+1) if (a[k]) r=k[2:0];
    end
    assign idx=r; assign valid=|a;
endmodule


