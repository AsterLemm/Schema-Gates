// =====================================================================
//  mask_low8.v
//  8-bit low-mask (n low bits set).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mask_low8(input [3:0] n, output [7:0] y);
    // define n input 200.120.255
    // define y output 120.255.160
    assign y = ({8{1'b1}} >> (8-n)) & {8{|n}} | (n==8 ? {8{1'b1}} : ( ({8'b1} << n) - 1'b1));
endmodule


