// =====================================================================
//  addsub_saturating_unsigned32.v
//  32-bit unsigned saturating add/sub (clamp 0..max).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module addsub_saturating_unsigned32(input [31:0] a, input [31:0] b, input sub, output [31:0] result);
    // define a input 80.160.255
    // define b input 80.200.255
    // define sub input 200.120.255
    // define result output 120.255.160
    wire [32:0] add = {1'b0,a} + {1'b0,b};
    wire        bge = (b > a);
    wire [31:0] dif = a - b;
    assign result = sub ? (bge ? {32{1'b0}} : dif)
                        : (add[32] ? {32{1'b1}} : add[31:0]);
endmodule


