// =====================================================================
//  sqrt_comb4.v
//  4-bit integer square root (structural digit-by-digit non-restoring array).
//  Each stage: shift + structural subtractor + restore mux; no *, /, % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sqrt_comb4(input [3:0] a, output [1:0] root, output [2:0] remainder, output valid, output busy, output done);
    // define a input 80.160.255
    // define root output 120.255.160
    // define remainder output 120.255.160
    // define valid output 255.255.255
    wire [1:0] rt; wire [2:0] rm;
    sqcore4 c(.a(a), .root(rt), .rem(rm));
    assign root = rt; assign remainder = rm;
    assign valid=1'b1; assign busy=1'b0; assign done=1'b1;
endmodule

module sqcore4(input [3:0] a, output [1:0] root, output [2:0] rem);
    wire [5:0] rem0 = {6{1'b0}};
    wire [1:0] root0 = {2{1'b0}};
    wire [5:0] sr0 = {rem0[3:0], a[3], a[2]};
    wire [5:0] ts0 = {root0, 2'b01};
    wire [5:0] df0; wire bw0;
    sqsub6_0 ss0(.a(sr0), .b(ts0), .diff(df0), .bout(bw0));
    wire ge0 = ~bw0;
    wire [5:0] rem1 = ge0 ? df0 : sr0;
    wire [1:0] root1 = {root0[0:0], ge0};
    wire [5:0] sr1 = {rem1[3:0], a[1], a[0]};
    wire [5:0] ts1 = {root1, 2'b01};
    wire [5:0] df1; wire bw1;
    sqsub6_1 ss1(.a(sr1), .b(ts1), .diff(df1), .bout(bw1));
    wire ge1 = ~bw1;
    wire [5:0] rem2 = ge1 ? df1 : sr1;
    wire [1:0] root2 = {root1[0:0], ge1};
    assign root = root2;
    assign rem  = rem2[2:0];
endmodule

module sqsub6_0(input [5:0] a, input [5:0] b, output [5:0] diff, output bout);
    wire [6:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    assign bout = ~c[6];
endmodule

module sqsub6_1(input [5:0] a, input [5:0] b, output [5:0] diff, output bout);
    wire [6:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    assign bout = ~c[6];
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


