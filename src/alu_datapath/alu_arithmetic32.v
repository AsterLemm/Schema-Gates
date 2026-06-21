// =====================================================================
//  alu_arithmetic32.v
//  32-bit arithmetic ALU (add/sub/inc/dec).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module alu_arithmetic32(input [31:0] a, input [31:0] b, input [1:0] op, output reg [31:0] y, output reg cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define op input 200.120.255
    // define y output 120.255.160
    // define cout output 255.120.120
    // op: 00 add, 01 sub, 10 inc a, 11 dec a
    reg [32:0] t;
    always @(*) begin case(op)
        2'b00: t = {1'b0,a} + {1'b0,b};
        2'b01: t = {1'b0,a} - {1'b0,b};
        2'b10: t = {1'b0,a} + 1'b1;
        2'b11: t = {1'b0,a} - 1'b1;
    endcase y=t[31:0]; cout=t[32]; end
endmodule


