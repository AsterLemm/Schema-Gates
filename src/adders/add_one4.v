// =====================================================================
//  add_one4.v
//  4-bit add-one (y=a+1).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_one4(input [3:0] a, output [3:0] y, output cout);
    // define a input 80.160.255   // define y output 120.255.160   // define cout output 255.120.120
    wire [4:0] c; assign c[0]=1'b1;
    half_adder ha0(.a(a[0]),.b(c[0]),.sum(y[0]),.carry(c[1]));
    half_adder ha1(.a(a[1]),.b(c[1]),.sum(y[1]),.carry(c[2]));
    half_adder ha2(.a(a[2]),.b(c[2]),.sum(y[2]),.carry(c[3]));
    half_adder ha3(.a(a[3]),.b(c[3]),.sum(y[3]),.carry(c[4]));
    assign cout=c[4];
endmodule

module half_adder(input a, input b, output sum, output carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule


