// =====================================================================
//  first_one_index32.v
//  32-bit index of first (lowest) set bit.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module first_one_index32(input [31:0] a, output [5:0] idx, output valid);
    // define a input 80.160.255   // define idx output 120.255.160   // define valid output 255.255.255
    integer k; reg [5:0] r; reg f;
    always @(*) begin r=0; f=0;
        for (k=0;k<32;k=k+1) if (a[k] && !f) begin r=k[5:0]; f=1; end
    end
    assign idx=r; assign valid=|a;
endmodule


