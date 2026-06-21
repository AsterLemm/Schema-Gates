// =====================================================================
//  alu_flags4.v
//  4-bit ALU with Z/N/C/V flags.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module alu_flags4(input [3:0] a, input [3:0] b, input [2:0] op, output reg [3:0] y, output zero, output negative, output carry, output overflow);
    // define a input 80.160.255
    // define b input 80.200.255
    // define op input 200.120.255
    // define y output 120.255.160
    // define zero output 255.255.255
    // define carry output 255.120.120
    reg [4:0] t;
    always @(*) begin t=5'b0; case(op)
        3'b000: t={1'b0,a}+{1'b0,b};
        3'b001: t={1'b0,a}-{1'b0,b};
        3'b010: t={1'b0,(a&b)};
        3'b011: t={1'b0,(a|b)};
        3'b100: t={1'b0,(a^b)};
        3'b101: t={1'b0,(~a)};
        3'b110: t={1'b0,a}<<1;
        3'b111: t={1'b0,a}>>1;
    endcase y=t[3:0]; end
    assign zero = (y==4'b0);
    assign negative = y[3];
    assign carry = t[4];
    wire is_add = (op==3'b000);
    wire is_sub = (op==3'b001);
    assign overflow = (is_add & (a[3]==b[3]) & (y[3]!=a[3]))
                    | (is_sub & (a[3]!=b[3]) & (y[3]!=a[3]));
endmodule


