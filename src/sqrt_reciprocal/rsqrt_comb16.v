// =====================================================================
//  rsqrt_comb16.v
//  16-bit reciprocal square root (structural sqrt + structural reciprocal divide).
//  No *, /, % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module rsqrt_comb16(input [15:0] a, output [15:0] result, output valid);
    // define a input 80.160.255
    // define result output 120.255.160
    // define valid output 255.255.255
    // 1/sqrt(a) scaled: (2^16-1) / floor(sqrt(a)), fully structural
    wire [7:0] rt; wire [8:0] rm;
    rsqcore16 sc(.a(a), .root(rt), .rem(rm));
    wire [15:0] rt_ext = {{8{1'b0}}, rt};
    wire azero = ~(|a);
    wire [15:0] num = {16{1'b1}};   // 2^16-1 numerator
    wire [15:0] q, r; wire rd0,rov,rv,rb,rdn;
    rsqdiv16 dv(.a(num), .b(rt_ext), .quotient(q), .remainder(r),
        .divide_by_zero(rd0), .overflow(rov), .valid(rv), .busy(rb), .done(rdn));
    assign result = azero ? {16{1'b1}} : q;
    assign valid = ~azero;
endmodule

module rsqcore16(input [15:0] a, output [7:0] root, output [8:0] rem);
    wire [17:0] rem0 = {18{1'b0}};
    wire [7:0] root0 = {8{1'b0}};
    wire [17:0] sr0 = {rem0[15:0], a[15], a[14]};
    wire [17:0] ts0 = {root0, 2'b01};
    wire [17:0] df0; wire bw0;
    sqsub18_0 ss0(.a(sr0), .b(ts0), .diff(df0), .bout(bw0));
    wire ge0 = ~bw0;
    wire [17:0] rem1 = ge0 ? df0 : sr0;
    wire [7:0] root1 = {root0[6:0], ge0};
    wire [17:0] sr1 = {rem1[15:0], a[13], a[12]};
    wire [17:0] ts1 = {root1, 2'b01};
    wire [17:0] df1; wire bw1;
    sqsub18_1 ss1(.a(sr1), .b(ts1), .diff(df1), .bout(bw1));
    wire ge1 = ~bw1;
    wire [17:0] rem2 = ge1 ? df1 : sr1;
    wire [7:0] root2 = {root1[6:0], ge1};
    wire [17:0] sr2 = {rem2[15:0], a[11], a[10]};
    wire [17:0] ts2 = {root2, 2'b01};
    wire [17:0] df2; wire bw2;
    sqsub18_2 ss2(.a(sr2), .b(ts2), .diff(df2), .bout(bw2));
    wire ge2 = ~bw2;
    wire [17:0] rem3 = ge2 ? df2 : sr2;
    wire [7:0] root3 = {root2[6:0], ge2};
    wire [17:0] sr3 = {rem3[15:0], a[9], a[8]};
    wire [17:0] ts3 = {root3, 2'b01};
    wire [17:0] df3; wire bw3;
    sqsub18_3 ss3(.a(sr3), .b(ts3), .diff(df3), .bout(bw3));
    wire ge3 = ~bw3;
    wire [17:0] rem4 = ge3 ? df3 : sr3;
    wire [7:0] root4 = {root3[6:0], ge3};
    wire [17:0] sr4 = {rem4[15:0], a[7], a[6]};
    wire [17:0] ts4 = {root4, 2'b01};
    wire [17:0] df4; wire bw4;
    sqsub18_4 ss4(.a(sr4), .b(ts4), .diff(df4), .bout(bw4));
    wire ge4 = ~bw4;
    wire [17:0] rem5 = ge4 ? df4 : sr4;
    wire [7:0] root5 = {root4[6:0], ge4};
    wire [17:0] sr5 = {rem5[15:0], a[5], a[4]};
    wire [17:0] ts5 = {root5, 2'b01};
    wire [17:0] df5; wire bw5;
    sqsub18_5 ss5(.a(sr5), .b(ts5), .diff(df5), .bout(bw5));
    wire ge5 = ~bw5;
    wire [17:0] rem6 = ge5 ? df5 : sr5;
    wire [7:0] root6 = {root5[6:0], ge5};
    wire [17:0] sr6 = {rem6[15:0], a[3], a[2]};
    wire [17:0] ts6 = {root6, 2'b01};
    wire [17:0] df6; wire bw6;
    sqsub18_6 ss6(.a(sr6), .b(ts6), .diff(df6), .bout(bw6));
    wire ge6 = ~bw6;
    wire [17:0] rem7 = ge6 ? df6 : sr6;
    wire [7:0] root7 = {root6[6:0], ge6};
    wire [17:0] sr7 = {rem7[15:0], a[1], a[0]};
    wire [17:0] ts7 = {root7, 2'b01};
    wire [17:0] df7; wire bw7;
    sqsub18_7 ss7(.a(sr7), .b(ts7), .diff(df7), .bout(bw7));
    wire ge7 = ~bw7;
    wire [17:0] rem8 = ge7 ? df7 : sr7;
    wire [7:0] root8 = {root7[6:0], ge7};
    assign root = root8;
    assign rem  = rem8[8:0];
endmodule

module sqsub18_0(input [17:0] a, input [17:0] b, output [17:0] diff, output bout);
    wire [18:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    full_adder fa17(.a(a[17]),.b(~b[17]),.cin(c[17]),.sum(diff[17]),.cout(c[18]));
    assign bout = ~c[18];
endmodule

module sqsub18_1(input [17:0] a, input [17:0] b, output [17:0] diff, output bout);
    wire [18:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    full_adder fa17(.a(a[17]),.b(~b[17]),.cin(c[17]),.sum(diff[17]),.cout(c[18]));
    assign bout = ~c[18];
endmodule

module sqsub18_2(input [17:0] a, input [17:0] b, output [17:0] diff, output bout);
    wire [18:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    full_adder fa17(.a(a[17]),.b(~b[17]),.cin(c[17]),.sum(diff[17]),.cout(c[18]));
    assign bout = ~c[18];
endmodule

module sqsub18_3(input [17:0] a, input [17:0] b, output [17:0] diff, output bout);
    wire [18:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    full_adder fa17(.a(a[17]),.b(~b[17]),.cin(c[17]),.sum(diff[17]),.cout(c[18]));
    assign bout = ~c[18];
endmodule

module sqsub18_4(input [17:0] a, input [17:0] b, output [17:0] diff, output bout);
    wire [18:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    full_adder fa17(.a(a[17]),.b(~b[17]),.cin(c[17]),.sum(diff[17]),.cout(c[18]));
    assign bout = ~c[18];
endmodule

module sqsub18_5(input [17:0] a, input [17:0] b, output [17:0] diff, output bout);
    wire [18:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    full_adder fa17(.a(a[17]),.b(~b[17]),.cin(c[17]),.sum(diff[17]),.cout(c[18]));
    assign bout = ~c[18];
endmodule

module sqsub18_6(input [17:0] a, input [17:0] b, output [17:0] diff, output bout);
    wire [18:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    full_adder fa17(.a(a[17]),.b(~b[17]),.cin(c[17]),.sum(diff[17]),.cout(c[18]));
    assign bout = ~c[18];
endmodule

module sqsub18_7(input [17:0] a, input [17:0] b, output [17:0] diff, output bout);
    wire [18:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    full_adder fa17(.a(a[17]),.b(~b[17]),.cin(c[17]),.sum(diff[17]),.cout(c[18]));
    assign bout = ~c[18];
endmodule


module rsqdiv16(input [15:0] a, input [15:0] b,
    output [15:0] quotient, output [15:0] remainder,
    output divide_by_zero, output overflow, output valid, output busy, output done);
    wire dz = ~(|b);
    wire [16:0] rem0 = {17{1'b0}};
    wire [16:0] sh0 = {rem0[15:0], a[15]};
    wire [16:0] tr0; wire bo0;
    subw17_0 sub0(.a(sh0), .b({1'b0,b}), .diff(tr0), .bout(bo0));
    wire q0 = ~bo0;
    wire [16:0] rem1 = q0 ? tr0 : sh0;
    wire [16:0] sh1 = {rem1[15:0], a[14]};
    wire [16:0] tr1; wire bo1;
    subw17_1 sub1(.a(sh1), .b({1'b0,b}), .diff(tr1), .bout(bo1));
    wire q1 = ~bo1;
    wire [16:0] rem2 = q1 ? tr1 : sh1;
    wire [16:0] sh2 = {rem2[15:0], a[13]};
    wire [16:0] tr2; wire bo2;
    subw17_2 sub2(.a(sh2), .b({1'b0,b}), .diff(tr2), .bout(bo2));
    wire q2 = ~bo2;
    wire [16:0] rem3 = q2 ? tr2 : sh2;
    wire [16:0] sh3 = {rem3[15:0], a[12]};
    wire [16:0] tr3; wire bo3;
    subw17_3 sub3(.a(sh3), .b({1'b0,b}), .diff(tr3), .bout(bo3));
    wire q3 = ~bo3;
    wire [16:0] rem4 = q3 ? tr3 : sh3;
    wire [16:0] sh4 = {rem4[15:0], a[11]};
    wire [16:0] tr4; wire bo4;
    subw17_4 sub4(.a(sh4), .b({1'b0,b}), .diff(tr4), .bout(bo4));
    wire q4 = ~bo4;
    wire [16:0] rem5 = q4 ? tr4 : sh4;
    wire [16:0] sh5 = {rem5[15:0], a[10]};
    wire [16:0] tr5; wire bo5;
    subw17_5 sub5(.a(sh5), .b({1'b0,b}), .diff(tr5), .bout(bo5));
    wire q5 = ~bo5;
    wire [16:0] rem6 = q5 ? tr5 : sh5;
    wire [16:0] sh6 = {rem6[15:0], a[9]};
    wire [16:0] tr6; wire bo6;
    subw17_6 sub6(.a(sh6), .b({1'b0,b}), .diff(tr6), .bout(bo6));
    wire q6 = ~bo6;
    wire [16:0] rem7 = q6 ? tr6 : sh6;
    wire [16:0] sh7 = {rem7[15:0], a[8]};
    wire [16:0] tr7; wire bo7;
    subw17_7 sub7(.a(sh7), .b({1'b0,b}), .diff(tr7), .bout(bo7));
    wire q7 = ~bo7;
    wire [16:0] rem8 = q7 ? tr7 : sh7;
    wire [16:0] sh8 = {rem8[15:0], a[7]};
    wire [16:0] tr8; wire bo8;
    subw17_8 sub8(.a(sh8), .b({1'b0,b}), .diff(tr8), .bout(bo8));
    wire q8 = ~bo8;
    wire [16:0] rem9 = q8 ? tr8 : sh8;
    wire [16:0] sh9 = {rem9[15:0], a[6]};
    wire [16:0] tr9; wire bo9;
    subw17_9 sub9(.a(sh9), .b({1'b0,b}), .diff(tr9), .bout(bo9));
    wire q9 = ~bo9;
    wire [16:0] rem10 = q9 ? tr9 : sh9;
    wire [16:0] sh10 = {rem10[15:0], a[5]};
    wire [16:0] tr10; wire bo10;
    subw17_10 sub10(.a(sh10), .b({1'b0,b}), .diff(tr10), .bout(bo10));
    wire q10 = ~bo10;
    wire [16:0] rem11 = q10 ? tr10 : sh10;
    wire [16:0] sh11 = {rem11[15:0], a[4]};
    wire [16:0] tr11; wire bo11;
    subw17_11 sub11(.a(sh11), .b({1'b0,b}), .diff(tr11), .bout(bo11));
    wire q11 = ~bo11;
    wire [16:0] rem12 = q11 ? tr11 : sh11;
    wire [16:0] sh12 = {rem12[15:0], a[3]};
    wire [16:0] tr12; wire bo12;
    subw17_12 sub12(.a(sh12), .b({1'b0,b}), .diff(tr12), .bout(bo12));
    wire q12 = ~bo12;
    wire [16:0] rem13 = q12 ? tr12 : sh12;
    wire [16:0] sh13 = {rem13[15:0], a[2]};
    wire [16:0] tr13; wire bo13;
    subw17_13 sub13(.a(sh13), .b({1'b0,b}), .diff(tr13), .bout(bo13));
    wire q13 = ~bo13;
    wire [16:0] rem14 = q13 ? tr13 : sh13;
    wire [16:0] sh14 = {rem14[15:0], a[1]};
    wire [16:0] tr14; wire bo14;
    subw17_14 sub14(.a(sh14), .b({1'b0,b}), .diff(tr14), .bout(bo14));
    wire q14 = ~bo14;
    wire [16:0] rem15 = q14 ? tr14 : sh14;
    wire [16:0] sh15 = {rem15[15:0], a[0]};
    wire [16:0] tr15; wire bo15;
    subw17_15 sub15(.a(sh15), .b({1'b0,b}), .diff(tr15), .bout(bo15));
    wire q15 = ~bo15;
    wire [16:0] rem16 = q15 ? tr15 : sh15;
    assign quotient  = dz ? {16{1'b1}} : {q0, q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11, q12, q13, q14, q15};
    assign remainder = dz ? a : rem16[15:0];
    assign overflow = 1'b0;
    assign valid = ~dz;
    assign busy  = 1'b0;
    assign done  = 1'b1;
endmodule

module subw17_0(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_1(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_2(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_3(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_4(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_5(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_6(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_7(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_8(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_9(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_10(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_11(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_12(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_13(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_14(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
endmodule

module subw17_15(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
    wire [17:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    full_adder fa9(.a(a[9]),.b(~b[9]),.cin(c[9]),.sum(diff[9]),.cout(c[10]));
    full_adder fa10(.a(a[10]),.b(~b[10]),.cin(c[10]),.sum(diff[10]),.cout(c[11]));
    full_adder fa11(.a(a[11]),.b(~b[11]),.cin(c[11]),.sum(diff[11]),.cout(c[12]));
    full_adder fa12(.a(a[12]),.b(~b[12]),.cin(c[12]),.sum(diff[12]),.cout(c[13]));
    full_adder fa13(.a(a[13]),.b(~b[13]),.cin(c[13]),.sum(diff[13]),.cout(c[14]));
    full_adder fa14(.a(a[14]),.b(~b[14]),.cin(c[14]),.sum(diff[14]),.cout(c[15]));
    full_adder fa15(.a(a[15]),.b(~b[15]),.cin(c[15]),.sum(diff[15]),.cout(c[16]));
    full_adder fa16(.a(a[16]),.b(~b[16]),.cin(c[16]),.sum(diff[16]),.cout(c[17]));
    assign bout = ~c[17];
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


