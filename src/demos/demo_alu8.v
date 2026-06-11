// =====================================================================
//  demo_alu8.v
//  Demo: 8-bit ALU with zero and carry flags.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module demo_alu8(input [7:0] a, input [7:0] b, input [2:0] op, output reg [7:0] y, output zero, output carry);
    // define a input 80.160.255   // define b input 80.200.255   // define op input 200.120.255   // define y output 120.255.160   // define zero output 255.255.255
    reg [8:0] t;
    always @(*) begin case(op)
        3'b000: t={1'b0,a}+{1'b0,b};
        3'b001: t={1'b0,a}-{1'b0,b};
        3'b010: t={1'b0,(a&b)};
        3'b011: t={1'b0,(a|b)};
        3'b100: t={1'b0,(a^b)};
        3'b101: t={1'b0,(~a)};
        3'b110: t={1'b0,a}<<1;
        3'b111: t={1'b0,a}>>1;
    endcase y=t[7:0]; end
    assign zero=(y==8'b0); assign carry=t[8];
endmodule


