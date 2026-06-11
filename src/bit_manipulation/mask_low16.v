// =====================================================================
//  mask_low16.v
//  16-bit low-mask (n low bits set).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mask_low16(input [4:0] n, output [15:0] y);
    // define n input 200.120.255   // define y output 120.255.160
    assign y = ({16{1'b1}} >> (16-n)) & {16{|n}} | (n==16 ? {16{1'b1}} : ( ({16'b1} << n) - 1'b1));
endmodule


