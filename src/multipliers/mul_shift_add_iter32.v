// =====================================================================
//  mul_shift_add_iter32.v
//  32x32 iterative shift-add multiplier (32 cycles).
//  Structural ripple-adder accumulate step; no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mul_shift_add_iter32(input clk, input rst, input start, input [31:0] a, input [31:0] b, output reg [63:0] product, output reg done);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define start input 255.180.80
    // define a input 80.160.255
    // define b input 80.200.255
    // define product output 120.255.160
    // define done output 255.255.255
    reg [63:0] acc; reg [31:0] mplier; reg [63:0] mcand_sh; reg [5:0] i; reg busy;
    wire [63:0] sum_next; wire co;
    rca64 step(.a(acc), .b(mcand_sh), .cin(1'b0), .sum(sum_next), .cout(co));
    always @(posedge clk) begin
        if (rst) begin busy<=0; done<=0; acc<=0; product<=0; i<=0; end
        else if (start) begin busy<=1; done<=0; acc<=0; i<=0;
            mplier<=b; mcand_sh<={{32{1'b0}}, a}; end
        else if (busy) begin
            if (mplier[0]) acc <= sum_next;
            mplier <= mplier >> 1;
            mcand_sh <= mcand_sh << 1;
            i <= i + 1'b1;
            if (i == 31) begin busy<=0; done<=1; product <= (mplier[0] ? sum_next : acc); end
        end else done<=0;
    end
endmodule

module rca64(input [63:0] a, input [63:0] b, input cin, output [63:0] sum, output cout);
    wire [64:0] c; assign c[0]=cin;
    full_adder fa0(.a(a[0]),.b(b[0]),.cin(c[0]),.sum(sum[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(b[1]),.cin(c[1]),.sum(sum[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(b[2]),.cin(c[2]),.sum(sum[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(b[3]),.cin(c[3]),.sum(sum[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(b[4]),.cin(c[4]),.sum(sum[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(b[5]),.cin(c[5]),.sum(sum[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(b[6]),.cin(c[6]),.sum(sum[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(b[7]),.cin(c[7]),.sum(sum[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(b[8]),.cin(c[8]),.sum(sum[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(b[9]),.cin(c[9]),.sum(sum[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(b[10]),.cin(c[10]),.sum(sum[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(b[11]),.cin(c[11]),.sum(sum[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(b[12]),.cin(c[12]),.sum(sum[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(b[13]),.cin(c[13]),.sum(sum[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(b[14]),.cin(c[14]),.sum(sum[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(b[15]),.cin(c[15]),.sum(sum[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(b[16]),.cin(c[16]),.sum(sum[16]),.cout(c[17]));
    full_adder fa17(.a(a[17]),.b(b[17]),.cin(c[17]),.sum(sum[17]),.cout(c[18]));
    full_adder fa18(.a(a[18]),.b(b[18]),.cin(c[18]),.sum(sum[18]),.cout(c[19]));
    full_adder fa19(.a(a[19]),.b(b[19]),.cin(c[19]),.sum(sum[19]),.cout(c[20]));
    full_adder fa20(.a(a[20]),.b(b[20]),.cin(c[20]),.sum(sum[20]),.cout(c[21]));
    full_adder fa21(.a(a[21]),.b(b[21]),.cin(c[21]),.sum(sum[21]),.cout(c[22]));
    full_adder fa22(.a(a[22]),.b(b[22]),.cin(c[22]),.sum(sum[22]),.cout(c[23]));
    full_adder fa23(.a(a[23]),.b(b[23]),.cin(c[23]),.sum(sum[23]),.cout(c[24]));
    full_adder fa24(.a(a[24]),.b(b[24]),.cin(c[24]),.sum(sum[24]),.cout(c[25]));
    full_adder fa25(.a(a[25]),.b(b[25]),.cin(c[25]),.sum(sum[25]),.cout(c[26]));
    full_adder fa26(.a(a[26]),.b(b[26]),.cin(c[26]),.sum(sum[26]),.cout(c[27]));
    full_adder fa27(.a(a[27]),.b(b[27]),.cin(c[27]),.sum(sum[27]),.cout(c[28]));
    full_adder fa28(.a(a[28]),.b(b[28]),.cin(c[28]),.sum(sum[28]),.cout(c[29]));
    full_adder fa29(.a(a[29]),.b(b[29]),.cin(c[29]),.sum(sum[29]),.cout(c[30]));
    full_adder fa30(.a(a[30]),.b(b[30]),.cin(c[30]),.sum(sum[30]),.cout(c[31]));
    full_adder fa31(.a(a[31]),.b(b[31]),.cin(c[31]),.sum(sum[31]),.cout(c[32]));
    full_adder fa32(.a(a[32]),.b(b[32]),.cin(c[32]),.sum(sum[32]),.cout(c[33]));
    full_adder fa33(.a(a[33]),.b(b[33]),.cin(c[33]),.sum(sum[33]),.cout(c[34]));
    full_adder fa34(.a(a[34]),.b(b[34]),.cin(c[34]),.sum(sum[34]),.cout(c[35]));
    full_adder fa35(.a(a[35]),.b(b[35]),.cin(c[35]),.sum(sum[35]),.cout(c[36]));
    full_adder fa36(.a(a[36]),.b(b[36]),.cin(c[36]),.sum(sum[36]),.cout(c[37]));
    full_adder fa37(.a(a[37]),.b(b[37]),.cin(c[37]),.sum(sum[37]),.cout(c[38]));
    full_adder fa38(.a(a[38]),.b(b[38]),.cin(c[38]),.sum(sum[38]),.cout(c[39]));
    full_adder fa39(.a(a[39]),.b(b[39]),.cin(c[39]),.sum(sum[39]),.cout(c[40]));
    full_adder fa40(.a(a[40]),.b(b[40]),.cin(c[40]),.sum(sum[40]),.cout(c[41]));
    full_adder fa41(.a(a[41]),.b(b[41]),.cin(c[41]),.sum(sum[41]),.cout(c[42]));
    full_adder fa42(.a(a[42]),.b(b[42]),.cin(c[42]),.sum(sum[42]),.cout(c[43]));
    full_adder fa43(.a(a[43]),.b(b[43]),.cin(c[43]),.sum(sum[43]),.cout(c[44]));
    full_adder fa44(.a(a[44]),.b(b[44]),.cin(c[44]),.sum(sum[44]),.cout(c[45]));
    full_adder fa45(.a(a[45]),.b(b[45]),.cin(c[45]),.sum(sum[45]),.cout(c[46]));
    full_adder fa46(.a(a[46]),.b(b[46]),.cin(c[46]),.sum(sum[46]),.cout(c[47]));
    full_adder fa47(.a(a[47]),.b(b[47]),.cin(c[47]),.sum(sum[47]),.cout(c[48]));
    full_adder fa48(.a(a[48]),.b(b[48]),.cin(c[48]),.sum(sum[48]),.cout(c[49]));
    full_adder fa49(.a(a[49]),.b(b[49]),.cin(c[49]),.sum(sum[49]),.cout(c[50]));
    full_adder fa50(.a(a[50]),.b(b[50]),.cin(c[50]),.sum(sum[50]),.cout(c[51]));
    full_adder fa51(.a(a[51]),.b(b[51]),.cin(c[51]),.sum(sum[51]),.cout(c[52]));
    full_adder fa52(.a(a[52]),.b(b[52]),.cin(c[52]),.sum(sum[52]),.cout(c[53]));
    full_adder fa53(.a(a[53]),.b(b[53]),.cin(c[53]),.sum(sum[53]),.cout(c[54]));
    full_adder fa54(.a(a[54]),.b(b[54]),.cin(c[54]),.sum(sum[54]),.cout(c[55]));
    full_adder fa55(.a(a[55]),.b(b[55]),.cin(c[55]),.sum(sum[55]),.cout(c[56]));
    full_adder fa56(.a(a[56]),.b(b[56]),.cin(c[56]),.sum(sum[56]),.cout(c[57]));
    full_adder fa57(.a(a[57]),.b(b[57]),.cin(c[57]),.sum(sum[57]),.cout(c[58]));
    full_adder fa58(.a(a[58]),.b(b[58]),.cin(c[58]),.sum(sum[58]),.cout(c[59]));
    full_adder fa59(.a(a[59]),.b(b[59]),.cin(c[59]),.sum(sum[59]),.cout(c[60]));
    full_adder fa60(.a(a[60]),.b(b[60]),.cin(c[60]),.sum(sum[60]),.cout(c[61]));
    full_adder fa61(.a(a[61]),.b(b[61]),.cin(c[61]),.sum(sum[61]),.cout(c[62]));
    full_adder fa62(.a(a[62]),.b(b[62]),.cin(c[62]),.sum(sum[62]),.cout(c[63]));
    full_adder fa63(.a(a[63]),.b(b[63]),.cin(c[63]),.sum(sum[63]),.cout(c[64]));
    assign cout=c[64];
endmodule

module half_adder(input a, input b, output sum, output carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule

module full_adder(input a, input b, input cin, output sum, output cout);
    wire s0, c0, c1;
    half_adder ha0(.a(a),  .b(b),   .sum(s0),  .carry(c0));
    half_adder ha1(.a(s0), .b(cin), .sum(sum), .carry(c1));
    assign cout = c0 | c1;
endmodule


