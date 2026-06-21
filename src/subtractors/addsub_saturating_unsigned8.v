// =====================================================================
//  addsub_saturating_unsigned8.v
//  8-bit unsigned saturating add/sub (clamp 0..max).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module addsub_saturating_unsigned8(input [7:0] a, input [7:0] b, input sub, output [7:0] result);
    // define a input 80.160.255
    // define b input 80.200.255
    // define sub input 200.120.255
    // define result output 120.255.160
    wire [8:0] add = {1'b0,a} + {1'b0,b};
    wire        bge = (b > a);
    wire [7:0] dif = a - b;
    assign result = sub ? (bge ? {8{1'b0}} : dif)
                        : (add[8] ? {8{1'b1}} : add[7:0]);
endmodule


