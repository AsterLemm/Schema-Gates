// =====================================================================
//  sub_prefix_kogge_stone16.v
//  16-bit subtractor (two's complement on Kogge-Stone prefix adder).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sub_prefix_kogge_stone16(input [15:0] a, input [15:0] b, output [15:0] diff, output bout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define diff output 120.255.160
    // define bout output 255.120.120
    wire cout; ks_unit16 u(.a(a),.b(~b),.cin(1'b1),.sum(diff),.cout(cout));
    assign bout=~cout;
endmodule

module ks_unit16(input [15:0] a, input [15:0] b, input cin, output [15:0] sum, output cout);
    wire [15:0] p0,g0;
    assign p0[0]=a[0]^b[0]; assign g0[0]=a[0]&b[0];
    assign p0[1]=a[1]^b[1]; assign g0[1]=a[1]&b[1];
    assign p0[2]=a[2]^b[2]; assign g0[2]=a[2]&b[2];
    assign p0[3]=a[3]^b[3]; assign g0[3]=a[3]&b[3];
    assign p0[4]=a[4]^b[4]; assign g0[4]=a[4]&b[4];
    assign p0[5]=a[5]^b[5]; assign g0[5]=a[5]&b[5];
    assign p0[6]=a[6]^b[6]; assign g0[6]=a[6]&b[6];
    assign p0[7]=a[7]^b[7]; assign g0[7]=a[7]&b[7];
    assign p0[8]=a[8]^b[8]; assign g0[8]=a[8]&b[8];
    assign p0[9]=a[9]^b[9]; assign g0[9]=a[9]&b[9];
    assign p0[10]=a[10]^b[10]; assign g0[10]=a[10]&b[10];
    assign p0[11]=a[11]^b[11]; assign g0[11]=a[11]&b[11];
    assign p0[12]=a[12]^b[12]; assign g0[12]=a[12]&b[12];
    assign p0[13]=a[13]^b[13]; assign g0[13]=a[13]&b[13];
    assign p0[14]=a[14]^b[14]; assign g0[14]=a[14]&b[14];
    assign p0[15]=a[15]^b[15]; assign g0[15]=a[15]&b[15];
    wire [15:0] g1,p1;
    assign g1[0]=g0[0]; assign p1[0]=p0[0];
    bcell c0_1(.gk(g0[1]),.pk(p0[1]),.gj(g0[0]),.pj(p0[0]),.g(g1[1]),.p(p1[1]));
    bcell c0_2(.gk(g0[2]),.pk(p0[2]),.gj(g0[1]),.pj(p0[1]),.g(g1[2]),.p(p1[2]));
    bcell c0_3(.gk(g0[3]),.pk(p0[3]),.gj(g0[2]),.pj(p0[2]),.g(g1[3]),.p(p1[3]));
    bcell c0_4(.gk(g0[4]),.pk(p0[4]),.gj(g0[3]),.pj(p0[3]),.g(g1[4]),.p(p1[4]));
    bcell c0_5(.gk(g0[5]),.pk(p0[5]),.gj(g0[4]),.pj(p0[4]),.g(g1[5]),.p(p1[5]));
    bcell c0_6(.gk(g0[6]),.pk(p0[6]),.gj(g0[5]),.pj(p0[5]),.g(g1[6]),.p(p1[6]));
    bcell c0_7(.gk(g0[7]),.pk(p0[7]),.gj(g0[6]),.pj(p0[6]),.g(g1[7]),.p(p1[7]));
    bcell c0_8(.gk(g0[8]),.pk(p0[8]),.gj(g0[7]),.pj(p0[7]),.g(g1[8]),.p(p1[8]));
    bcell c0_9(.gk(g0[9]),.pk(p0[9]),.gj(g0[8]),.pj(p0[8]),.g(g1[9]),.p(p1[9]));
    bcell c0_10(.gk(g0[10]),.pk(p0[10]),.gj(g0[9]),.pj(p0[9]),.g(g1[10]),.p(p1[10]));
    bcell c0_11(.gk(g0[11]),.pk(p0[11]),.gj(g0[10]),.pj(p0[10]),.g(g1[11]),.p(p1[11]));
    bcell c0_12(.gk(g0[12]),.pk(p0[12]),.gj(g0[11]),.pj(p0[11]),.g(g1[12]),.p(p1[12]));
    bcell c0_13(.gk(g0[13]),.pk(p0[13]),.gj(g0[12]),.pj(p0[12]),.g(g1[13]),.p(p1[13]));
    bcell c0_14(.gk(g0[14]),.pk(p0[14]),.gj(g0[13]),.pj(p0[13]),.g(g1[14]),.p(p1[14]));
    bcell c0_15(.gk(g0[15]),.pk(p0[15]),.gj(g0[14]),.pj(p0[14]),.g(g1[15]),.p(p1[15]));
    wire [15:0] g2,p2;
    assign g2[0]=g1[0]; assign p2[0]=p1[0];
    assign g2[1]=g1[1]; assign p2[1]=p1[1];
    bcell c1_2(.gk(g1[2]),.pk(p1[2]),.gj(g1[0]),.pj(p1[0]),.g(g2[2]),.p(p2[2]));
    bcell c1_3(.gk(g1[3]),.pk(p1[3]),.gj(g1[1]),.pj(p1[1]),.g(g2[3]),.p(p2[3]));
    bcell c1_4(.gk(g1[4]),.pk(p1[4]),.gj(g1[2]),.pj(p1[2]),.g(g2[4]),.p(p2[4]));
    bcell c1_5(.gk(g1[5]),.pk(p1[5]),.gj(g1[3]),.pj(p1[3]),.g(g2[5]),.p(p2[5]));
    bcell c1_6(.gk(g1[6]),.pk(p1[6]),.gj(g1[4]),.pj(p1[4]),.g(g2[6]),.p(p2[6]));
    bcell c1_7(.gk(g1[7]),.pk(p1[7]),.gj(g1[5]),.pj(p1[5]),.g(g2[7]),.p(p2[7]));
    bcell c1_8(.gk(g1[8]),.pk(p1[8]),.gj(g1[6]),.pj(p1[6]),.g(g2[8]),.p(p2[8]));
    bcell c1_9(.gk(g1[9]),.pk(p1[9]),.gj(g1[7]),.pj(p1[7]),.g(g2[9]),.p(p2[9]));
    bcell c1_10(.gk(g1[10]),.pk(p1[10]),.gj(g1[8]),.pj(p1[8]),.g(g2[10]),.p(p2[10]));
    bcell c1_11(.gk(g1[11]),.pk(p1[11]),.gj(g1[9]),.pj(p1[9]),.g(g2[11]),.p(p2[11]));
    bcell c1_12(.gk(g1[12]),.pk(p1[12]),.gj(g1[10]),.pj(p1[10]),.g(g2[12]),.p(p2[12]));
    bcell c1_13(.gk(g1[13]),.pk(p1[13]),.gj(g1[11]),.pj(p1[11]),.g(g2[13]),.p(p2[13]));
    bcell c1_14(.gk(g1[14]),.pk(p1[14]),.gj(g1[12]),.pj(p1[12]),.g(g2[14]),.p(p2[14]));
    bcell c1_15(.gk(g1[15]),.pk(p1[15]),.gj(g1[13]),.pj(p1[13]),.g(g2[15]),.p(p2[15]));
    wire [15:0] g3,p3;
    assign g3[0]=g2[0]; assign p3[0]=p2[0];
    assign g3[1]=g2[1]; assign p3[1]=p2[1];
    assign g3[2]=g2[2]; assign p3[2]=p2[2];
    assign g3[3]=g2[3]; assign p3[3]=p2[3];
    bcell c2_4(.gk(g2[4]),.pk(p2[4]),.gj(g2[0]),.pj(p2[0]),.g(g3[4]),.p(p3[4]));
    bcell c2_5(.gk(g2[5]),.pk(p2[5]),.gj(g2[1]),.pj(p2[1]),.g(g3[5]),.p(p3[5]));
    bcell c2_6(.gk(g2[6]),.pk(p2[6]),.gj(g2[2]),.pj(p2[2]),.g(g3[6]),.p(p3[6]));
    bcell c2_7(.gk(g2[7]),.pk(p2[7]),.gj(g2[3]),.pj(p2[3]),.g(g3[7]),.p(p3[7]));
    bcell c2_8(.gk(g2[8]),.pk(p2[8]),.gj(g2[4]),.pj(p2[4]),.g(g3[8]),.p(p3[8]));
    bcell c2_9(.gk(g2[9]),.pk(p2[9]),.gj(g2[5]),.pj(p2[5]),.g(g3[9]),.p(p3[9]));
    bcell c2_10(.gk(g2[10]),.pk(p2[10]),.gj(g2[6]),.pj(p2[6]),.g(g3[10]),.p(p3[10]));
    bcell c2_11(.gk(g2[11]),.pk(p2[11]),.gj(g2[7]),.pj(p2[7]),.g(g3[11]),.p(p3[11]));
    bcell c2_12(.gk(g2[12]),.pk(p2[12]),.gj(g2[8]),.pj(p2[8]),.g(g3[12]),.p(p3[12]));
    bcell c2_13(.gk(g2[13]),.pk(p2[13]),.gj(g2[9]),.pj(p2[9]),.g(g3[13]),.p(p3[13]));
    bcell c2_14(.gk(g2[14]),.pk(p2[14]),.gj(g2[10]),.pj(p2[10]),.g(g3[14]),.p(p3[14]));
    bcell c2_15(.gk(g2[15]),.pk(p2[15]),.gj(g2[11]),.pj(p2[11]),.g(g3[15]),.p(p3[15]));
    wire [15:0] g4,p4;
    assign g4[0]=g3[0]; assign p4[0]=p3[0];
    assign g4[1]=g3[1]; assign p4[1]=p3[1];
    assign g4[2]=g3[2]; assign p4[2]=p3[2];
    assign g4[3]=g3[3]; assign p4[3]=p3[3];
    assign g4[4]=g3[4]; assign p4[4]=p3[4];
    assign g4[5]=g3[5]; assign p4[5]=p3[5];
    assign g4[6]=g3[6]; assign p4[6]=p3[6];
    assign g4[7]=g3[7]; assign p4[7]=p3[7];
    bcell c3_8(.gk(g3[8]),.pk(p3[8]),.gj(g3[0]),.pj(p3[0]),.g(g4[8]),.p(p4[8]));
    bcell c3_9(.gk(g3[9]),.pk(p3[9]),.gj(g3[1]),.pj(p3[1]),.g(g4[9]),.p(p4[9]));
    bcell c3_10(.gk(g3[10]),.pk(p3[10]),.gj(g3[2]),.pj(p3[2]),.g(g4[10]),.p(p4[10]));
    bcell c3_11(.gk(g3[11]),.pk(p3[11]),.gj(g3[3]),.pj(p3[3]),.g(g4[11]),.p(p4[11]));
    bcell c3_12(.gk(g3[12]),.pk(p3[12]),.gj(g3[4]),.pj(p3[4]),.g(g4[12]),.p(p4[12]));
    bcell c3_13(.gk(g3[13]),.pk(p3[13]),.gj(g3[5]),.pj(p3[5]),.g(g4[13]),.p(p4[13]));
    bcell c3_14(.gk(g3[14]),.pk(p3[14]),.gj(g3[6]),.pj(p3[6]),.g(g4[14]),.p(p4[14]));
    bcell c3_15(.gk(g3[15]),.pk(p3[15]),.gj(g3[7]),.pj(p3[7]),.g(g4[15]),.p(p4[15]));
    wire [16:0] c; assign c[0]=cin;
    assign c[1]=g4[0]|(p4[0]&cin);
    assign c[2]=g4[1]|(p4[1]&cin);
    assign c[3]=g4[2]|(p4[2]&cin);
    assign c[4]=g4[3]|(p4[3]&cin);
    assign c[5]=g4[4]|(p4[4]&cin);
    assign c[6]=g4[5]|(p4[5]&cin);
    assign c[7]=g4[6]|(p4[6]&cin);
    assign c[8]=g4[7]|(p4[7]&cin);
    assign c[9]=g4[8]|(p4[8]&cin);
    assign c[10]=g4[9]|(p4[9]&cin);
    assign c[11]=g4[10]|(p4[10]&cin);
    assign c[12]=g4[11]|(p4[11]&cin);
    assign c[13]=g4[12]|(p4[12]&cin);
    assign c[14]=g4[13]|(p4[13]&cin);
    assign c[15]=g4[14]|(p4[14]&cin);
    assign c[16]=g4[15]|(p4[15]&cin);
    assign cout=c[16];
    assign sum[0]=p0[0]^c[0];
    assign sum[1]=p0[1]^c[1];
    assign sum[2]=p0[2]^c[2];
    assign sum[3]=p0[3]^c[3];
    assign sum[4]=p0[4]^c[4];
    assign sum[5]=p0[5]^c[5];
    assign sum[6]=p0[6]^c[6];
    assign sum[7]=p0[7]^c[7];
    assign sum[8]=p0[8]^c[8];
    assign sum[9]=p0[9]^c[9];
    assign sum[10]=p0[10]^c[10];
    assign sum[11]=p0[11]^c[11];
    assign sum[12]=p0[12]^c[12];
    assign sum[13]=p0[13]^c[13];
    assign sum[14]=p0[14]^c[14];
    assign sum[15]=p0[15]^c[15];
endmodule

module bcell(input gk,input pk,input gj,input pj,output g,output p);
    assign g=gk|(pk&gj); assign p=pk&pj;
endmodule


