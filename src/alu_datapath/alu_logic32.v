// =====================================================================
//  alu_logic32.v
//  32-bit logic ALU (AND/OR/XOR/NOT).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module alu_logic32(input [31:0] a, input [31:0] b, input [1:0] op, output reg [31:0] y);
    // define a input 80.160.255   // define b input 80.200.255   // define op input 200.120.255   // define y output 120.255.160
    // op: 00 AND, 01 OR, 10 XOR, 11 NOT a
    always @(*) case(op) 2'b00:y=a&b; 2'b01:y=a|b; 2'b10:y=a^b; 2'b11:y=~a; endcase
endmodule


