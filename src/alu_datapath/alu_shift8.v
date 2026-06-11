// =====================================================================
//  alu_shift8.v
//  8-bit shift ALU (shl/shr/sar/rol).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module alu_shift8(input [7:0] a, input [2:0] sh, input [1:0] op, output reg [7:0] y);
    // define a input 80.160.255   // define sh input 200.120.255   // define op input 200.120.255   // define y output 120.255.160
    // op: 00 shl 01 shr 10 sar 11 rotate-left
    always @(*) case(op)
        2'b00: y = a << sh;
        2'b01: y = a >> sh;
        2'b10: y = $signed(a) >>> sh;
        2'b11: y = (a << sh) | (a >> (8-sh));
    endcase
endmodule


