// =====================================================================
//  mul_shift_add_iter4.v
//  4x4 iterative shift-add multiplier (4 cycles).
//  Structural ripple-adder accumulate step; no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module mul_shift_add_iter4(input clk, input rst, input start, input [3:0] a, input [3:0] b, output reg [7:0] product, output reg done);
    // define clk input 255.230.80   // define rst input 255.80.80   // define start input 255.180.80
    // define a input 80.160.255   // define b input 80.200.255   // define product output 120.255.160   // define done output 255.255.255
    reg [7:0] acc; reg [3:0] mplier; reg [7:0] mcand_sh; reg [2:0] i; reg busy;
    wire [7:0] sum_next; wire co;
    rca8 step(.a(acc), .b(mcand_sh), .cin(1'b0), .sum(sum_next), .cout(co));
    always @(posedge clk) begin
        if (rst) begin busy<=0; done<=0; acc<=0; product<=0; i<=0; end
        else if (start) begin busy<=1; done<=0; acc<=0; i<=0;
            mplier<=b; mcand_sh<={{4{1'b0}}, a}; end
        else if (busy) begin
            if (mplier[0]) acc <= sum_next;
            mplier <= mplier >> 1;
            mcand_sh <= mcand_sh << 1;
            i <= i + 1'b1;
            if (i == 3) begin busy<=0; done<=1; product <= (mplier[0] ? sum_next : acc); end
        end else done<=0;
    end
endmodule

module rca8(input [7:0] a, input [7:0] b, input cin, output [7:0] sum, output cout);
    wire [8:0] c; assign c[0]=cin;
    full_adder fa0(.a(a[0]),.b(b[0]),.cin(c[0]),.sum(sum[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(b[1]),.cin(c[1]),.sum(sum[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(b[2]),.cin(c[2]),.sum(sum[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(b[3]),.cin(c[3]),.sum(sum[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(b[4]),.cin(c[4]),.sum(sum[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(b[5]),.cin(c[5]),.sum(sum[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(b[6]),.cin(c[6]),.sum(sum[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(b[7]),.cin(c[7]),.sum(sum[7]),.cout(c[8]));
    assign cout=c[8];
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


