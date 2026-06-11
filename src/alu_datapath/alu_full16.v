// =====================================================================
//  alu_full16.v
//  16-bit full ALU (16 ops + flags).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module alu_full16(input [15:0] a, input [15:0] b, input [3:0] op,
                   output reg [15:0] y, output zero, output negative, output carry, output overflow);
    // define a input 80.160.255   // define b input 80.200.255   // define op input 200.120.255
    // define y output 120.255.160   // define zero output 255.255.255
    reg [16:0] t;
    always @(*) begin t=17'b0; case(op)
        4'h0: t={1'b0,a}+{1'b0,b};        // ADD
        4'h1: t={1'b0,a}-{1'b0,b};        // SUB
        4'h2: t={1'b0,a}+1'b1;            // INC
        4'h3: t={1'b0,a}-1'b1;            // DEC
        4'h4: t={1'b0,(a&b)};             // AND
        4'h5: t={1'b0,(a|b)};             // OR
        4'h6: t={1'b0,(a^b)};             // XOR
        4'h7: t={1'b0,(~a)};              // NOT
        4'h8: t={1'b0,a}<<1;              // SHL
        4'h9: t={1'b0,a}>>1;              // SHR
        4'ha: t={1'b0,($signed(a)>>>1)};  // SAR
        4'hb: t={1'b0,((a<<1)|(a>>15))};// ROL
        4'hc: t={17{1'b0}} | (a<b);    // SLT (unsigned)
        4'hd: t={17{1'b0}} | (a==b);   // SEQ
        4'he: t={1'b0,a};                 // PASS A
        4'hf: t={1'b0,b};                 // PASS B
    endcase y=t[15:0]; end
    assign zero=(y==16'b0); assign negative=y[15]; assign carry=t[16];
    assign overflow=(op==4'h0)&(a[15]==b[15])&(y[15]!=a[15]);
endmodule


