// =====================================================================
//  fp8_mul.v
//  fp8 (E4M3) multiplier (structural 4x4 mantissa multiply); no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp8_mul(input [7:0] a, input [7:0] b, output reg [7:0] y);
    // define a input 80.160.255
    // define b input 80.200.255
    // define y output 120.255.160
    wire sa=a[7], sb=b[7];
    wire [3:0] ea=a[6:3], eb=b[6:3];
    wire [3:0] ma={|ea,a[2:0]}, mb={|eb,b[2:0]};
    wire [7:0] prod_raw;
    fp8m_mul mm(.a(ma), .b(mb), .product(prod_raw));
    reg [7:0] prod; reg signed [5:0] exp_res;
    always @(*) begin
        if (ea==0||eb==0) y={sa^sb,7'b0};
        else begin prod=prod_raw; exp_res=ea+eb-7;
            if (prod[7]) begin prod=prod>>1; exp_res=exp_res+1; end
            if (exp_res<=0) y={sa^sb,7'b0};
            else if (exp_res>=15) y={sa^sb,4'b1111,3'b0};
            else y={sa^sb,exp_res[3:0],prod[5:3]};
        end
    end
endmodule

module fp8m_mul(input [3:0] a, input [3:0] b, output [7:0] product);
    wire pp0_0 = a[0] & b[0];
    wire pp0_1 = a[1] & b[0];
    wire pp0_2 = a[2] & b[0];
    wire pp0_3 = a[3] & b[0];
    wire pp1_0 = a[0] & b[1];
    wire pp1_1 = a[1] & b[1];
    wire pp1_2 = a[2] & b[1];
    wire pp1_3 = a[3] & b[1];
    wire pp2_0 = a[0] & b[2];
    wire pp2_1 = a[1] & b[2];
    wire pp2_2 = a[2] & b[2];
    wire pp2_3 = a[3] & b[2];
    wire pp3_0 = a[0] & b[3];
    wire pp3_1 = a[1] & b[3];
    wire pp3_2 = a[2] & b[3];
    wire pp3_3 = a[3] & b[3];
    wire [7:0] row0 = {1'b0, 1'b0, 1'b0, 1'b0, pp0_3, pp0_2, pp0_1, pp0_0};
    wire [7:0] row1 = {1'b0, 1'b0, 1'b0, pp1_3, pp1_2, pp1_1, pp1_0, 1'b0};
    wire [7:0] row2 = {1'b0, 1'b0, pp2_3, pp2_2, pp2_1, pp2_0, 1'b0, 1'b0};
    wire [7:0] row3 = {1'b0, pp3_3, pp3_2, pp3_1, pp3_0, 1'b0, 1'b0, 1'b0};
    wire [7:0] acc1; wire co1;
    rca8 add1(.a(row0),.b(row1),.cin(1'b0),.sum(acc1),.cout(co1));
    wire [7:0] acc2; wire co2;
    rca8 add2(.a(acc1),.b(row2),.cin(1'b0),.sum(acc2),.cout(co2));
    wire [7:0] acc3; wire co3;
    rca8 add3(.a(acc2),.b(row3),.cin(1'b0),.sum(acc3),.cout(co3));
    assign product = acc3;
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


