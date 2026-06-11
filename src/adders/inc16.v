// =====================================================================
//  inc16.v
//  16-bit incrementer (y=a+1), half-adder carry chain.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module inc16(input [15:0] a, output [15:0] y, output cout);
    // define a input 80.160.255   // define y output 120.255.160   // define cout output 255.120.120
    wire [16:0] c; assign c[0]=1'b1;
    half_adder ha0(.a(a[0]),.b(c[0]),.sum(y[0]),.carry(c[1]));
    half_adder ha1(.a(a[1]),.b(c[1]),.sum(y[1]),.carry(c[2]));
    half_adder ha2(.a(a[2]),.b(c[2]),.sum(y[2]),.carry(c[3]));
    half_adder ha3(.a(a[3]),.b(c[3]),.sum(y[3]),.carry(c[4]));
    half_adder ha4(.a(a[4]),.b(c[4]),.sum(y[4]),.carry(c[5]));
    half_adder ha5(.a(a[5]),.b(c[5]),.sum(y[5]),.carry(c[6]));
    half_adder ha6(.a(a[6]),.b(c[6]),.sum(y[6]),.carry(c[7]));
    half_adder ha7(.a(a[7]),.b(c[7]),.sum(y[7]),.carry(c[8]));
    half_adder ha8(.a(a[8]),.b(c[8]),.sum(y[8]),.carry(c[9]));
    half_adder ha9(.a(a[9]),.b(c[9]),.sum(y[9]),.carry(c[10]));
    half_adder ha10(.a(a[10]),.b(c[10]),.sum(y[10]),.carry(c[11]));
    half_adder ha11(.a(a[11]),.b(c[11]),.sum(y[11]),.carry(c[12]));
    half_adder ha12(.a(a[12]),.b(c[12]),.sum(y[12]),.carry(c[13]));
    half_adder ha13(.a(a[13]),.b(c[13]),.sum(y[13]),.carry(c[14]));
    half_adder ha14(.a(a[14]),.b(c[14]),.sum(y[14]),.carry(c[15]));
    half_adder ha15(.a(a[15]),.b(c[15]),.sum(y[15]),.carry(c[16]));
    assign cout=c[16];
endmodule

module half_adder(input a, input b, output sum, output carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule


