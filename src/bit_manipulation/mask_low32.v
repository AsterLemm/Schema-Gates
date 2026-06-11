// =====================================================================
//  mask_low32.v
//  32-bit low-mask (n low bits set).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mask_low32(input [5:0] n, output [31:0] y);
    // define n input 200.120.255   // define y output 120.255.160
    assign y = ({32{1'b1}} >> (32-n)) & {32{|n}} | (n==32 ? {32{1'b1}} : ( ({32'b1} << n) - 1'b1));
endmodule


