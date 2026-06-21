// =====================================================================
//  sqrt_comb16.v
//  16-bit integer square root (structural digit-by-digit non-restoring array).
//  Each stage: shift + structural subtractor + restore mux; no *, /, % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sqrt_comb16(input [15:0] a, output [7:0] root, output [8:0] remainder, output valid, output busy, output done);
    // define a input 80.160.255
    // define root output 120.255.160
    // define remainder output 120.255.160
    // define valid output 255.255.255
    wire [7:0] rt; wire [8:0] rm;
    sqcore16 c(.a(a), .root(rt), .rem(rm));
    assign root = rt; assign remainder = rm;
    assign valid=1'b1; assign busy=1'b0; assign done=1'b1;
endmodule

module sqcore16(input [15:0] a, output [7:0] root, output [8:0] rem);
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


