// =====================================================================
//  first_one_index8.v
//  8-bit index of first (lowest) set bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module first_one_index8(input [7:0] a, output [3:0] idx, output valid);
    // define a input 80.160.255   // define idx output 120.255.160   // define valid output 255.255.255
    integer k; reg [3:0] r; reg f;
    always @(*) begin r=0; f=0;
        for (k=0;k<8;k=k+1) if (a[k] && !f) begin r=k[3:0]; f=1; end
    end
    assign idx=r; assign valid=|a;
endmodule


