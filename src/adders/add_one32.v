// =====================================================================
//  add_one32.v
//  32-bit add-one (y=a+1).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_one32(input [31:0] a, output [31:0] y, output cout);
    // define a input 80.160.255
    // define y output 120.255.160
    // define cout output 255.120.120
    wire [32:0] c; assign c[0]=1'b1;
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
    half_adder ha16(.a(a[16]),.b(c[16]),.sum(y[16]),.carry(c[17]));
    half_adder ha17(.a(a[17]),.b(c[17]),.sum(y[17]),.carry(c[18]));
    half_adder ha18(.a(a[18]),.b(c[18]),.sum(y[18]),.carry(c[19]));
    half_adder ha19(.a(a[19]),.b(c[19]),.sum(y[19]),.carry(c[20]));
    half_adder ha20(.a(a[20]),.b(c[20]),.sum(y[20]),.carry(c[21]));
    half_adder ha21(.a(a[21]),.b(c[21]),.sum(y[21]),.carry(c[22]));
    half_adder ha22(.a(a[22]),.b(c[22]),.sum(y[22]),.carry(c[23]));
    half_adder ha23(.a(a[23]),.b(c[23]),.sum(y[23]),.carry(c[24]));
    half_adder ha24(.a(a[24]),.b(c[24]),.sum(y[24]),.carry(c[25]));
    half_adder ha25(.a(a[25]),.b(c[25]),.sum(y[25]),.carry(c[26]));
    half_adder ha26(.a(a[26]),.b(c[26]),.sum(y[26]),.carry(c[27]));
    half_adder ha27(.a(a[27]),.b(c[27]),.sum(y[27]),.carry(c[28]));
    half_adder ha28(.a(a[28]),.b(c[28]),.sum(y[28]),.carry(c[29]));
    half_adder ha29(.a(a[29]),.b(c[29]),.sum(y[29]),.carry(c[30]));
    half_adder ha30(.a(a[30]),.b(c[30]),.sum(y[30]),.carry(c[31]));
    half_adder ha31(.a(a[31]),.b(c[31]),.sum(y[31]),.carry(c[32]));
    assign cout=c[32];
endmodule

module half_adder(input a, input b, output sum, output carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule


