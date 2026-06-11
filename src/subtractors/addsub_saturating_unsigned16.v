// =====================================================================
//  addsub_saturating_unsigned16.v
//  16-bit unsigned saturating add/sub (clamp 0..max).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module addsub_saturating_unsigned16(input [15:0] a, input [15:0] b, input sub, output [15:0] result);
    // define a input 80.160.255   // define b input 80.200.255   // define sub input 200.120.255   // define result output 120.255.160
    wire [16:0] add = {1'b0,a} + {1'b0,b};
    wire        bge = (b > a);
    wire [15:0] dif = a - b;
    assign result = sub ? (bge ? {16{1'b0}} : dif)
                        : (add[16] ? {16{1'b1}} : add[15:0]);
endmodule


