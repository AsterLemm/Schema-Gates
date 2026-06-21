// =====================================================================
//  alu_basic32.v
//  32-bit basic ALU (8 ops).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module alu_basic32(input [31:0] a, input [31:0] b, input [2:0] op, output reg [31:0] y);
    // define a input 80.160.255
    // define b input 80.200.255
    // define op input 200.120.255
    // define y output 120.255.160
    // op: 000 add 001 sub 010 and 011 or 100 xor 101 not 110 shl 111 shr
    always @(*) case(op)
        3'b000:y=a+b; 3'b001:y=a-b; 3'b010:y=a&b; 3'b011:y=a|b;
        3'b100:y=a^b; 3'b101:y=~a;  3'b110:y=a<<1; 3'b111:y=a>>1;
    endcase
endmodule


