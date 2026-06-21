// =====================================================================
//  add_one8.v
//  8-bit add-one (y=a+1).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_one8(input [7:0] a, output [7:0] y, output cout);
    // define a input 80.160.255
    // define y output 120.255.160
    // define cout output 255.120.120
    wire [8:0] c; assign c[0]=1'b1;
    half_adder ha0(.a(a[0]),.b(c[0]),.sum(y[0]),.carry(c[1]));
    half_adder ha1(.a(a[1]),.b(c[1]),.sum(y[1]),.carry(c[2]));
    half_adder ha2(.a(a[2]),.b(c[2]),.sum(y[2]),.carry(c[3]));
    half_adder ha3(.a(a[3]),.b(c[3]),.sum(y[3]),.carry(c[4]));
    half_adder ha4(.a(a[4]),.b(c[4]),.sum(y[4]),.carry(c[5]));
    half_adder ha5(.a(a[5]),.b(c[5]),.sum(y[5]),.carry(c[6]));
    half_adder ha6(.a(a[6]),.b(c[6]),.sum(y[6]),.carry(c[7]));
    half_adder ha7(.a(a[7]),.b(c[7]),.sum(y[7]),.carry(c[8]));
    assign cout=c[8];
endmodule

module half_adder(input a, input b, output sum, output carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule


