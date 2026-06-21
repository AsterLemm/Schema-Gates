// =====================================================================
//  sub_borrow_ripple32.v
//  32-bit borrow-ripple subtractor (full_subtractor chain).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sub_borrow_ripple32(input [31:0] a, input [31:0] b, input bin, output [31:0] diff, output bout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define bin input 255.230.80
    // define diff output 120.255.160
    // define bout output 255.120.120
    wire [32:0] bw; assign bw[0]=bin;
    full_subtractor fs0(.a(a[0]),.b(b[0]),.bin(bw[0]),.diff(diff[0]),.bout(bw[1]));
    full_subtractor fs1(.a(a[1]),.b(b[1]),.bin(bw[1]),.diff(diff[1]),.bout(bw[2]));
    full_subtractor fs2(.a(a[2]),.b(b[2]),.bin(bw[2]),.diff(diff[2]),.bout(bw[3]));
    full_subtractor fs3(.a(a[3]),.b(b[3]),.bin(bw[3]),.diff(diff[3]),.bout(bw[4]));
    full_subtractor fs4(.a(a[4]),.b(b[4]),.bin(bw[4]),.diff(diff[4]),.bout(bw[5]));
    full_subtractor fs5(.a(a[5]),.b(b[5]),.bin(bw[5]),.diff(diff[5]),.bout(bw[6]));
    full_subtractor fs6(.a(a[6]),.b(b[6]),.bin(bw[6]),.diff(diff[6]),.bout(bw[7]));
    full_subtractor fs7(.a(a[7]),.b(b[7]),.bin(bw[7]),.diff(diff[7]),.bout(bw[8]));
    full_subtractor fs8(.a(a[8]),.b(b[8]),.bin(bw[8]),.diff(diff[8]),.bout(bw[9]));
    full_subtractor fs9(.a(a[9]),.b(b[9]),.bin(bw[9]),.diff(diff[9]),.bout(bw[10]));
    full_subtractor fs10(.a(a[10]),.b(b[10]),.bin(bw[10]),.diff(diff[10]),.bout(bw[11]));
    full_subtractor fs11(.a(a[11]),.b(b[11]),.bin(bw[11]),.diff(diff[11]),.bout(bw[12]));
    full_subtractor fs12(.a(a[12]),.b(b[12]),.bin(bw[12]),.diff(diff[12]),.bout(bw[13]));
    full_subtractor fs13(.a(a[13]),.b(b[13]),.bin(bw[13]),.diff(diff[13]),.bout(bw[14]));
    full_subtractor fs14(.a(a[14]),.b(b[14]),.bin(bw[14]),.diff(diff[14]),.bout(bw[15]));
    full_subtractor fs15(.a(a[15]),.b(b[15]),.bin(bw[15]),.diff(diff[15]),.bout(bw[16]));
    full_subtractor fs16(.a(a[16]),.b(b[16]),.bin(bw[16]),.diff(diff[16]),.bout(bw[17]));
    full_subtractor fs17(.a(a[17]),.b(b[17]),.bin(bw[17]),.diff(diff[17]),.bout(bw[18]));
    full_subtractor fs18(.a(a[18]),.b(b[18]),.bin(bw[18]),.diff(diff[18]),.bout(bw[19]));
    full_subtractor fs19(.a(a[19]),.b(b[19]),.bin(bw[19]),.diff(diff[19]),.bout(bw[20]));
    full_subtractor fs20(.a(a[20]),.b(b[20]),.bin(bw[20]),.diff(diff[20]),.bout(bw[21]));
    full_subtractor fs21(.a(a[21]),.b(b[21]),.bin(bw[21]),.diff(diff[21]),.bout(bw[22]));
    full_subtractor fs22(.a(a[22]),.b(b[22]),.bin(bw[22]),.diff(diff[22]),.bout(bw[23]));
    full_subtractor fs23(.a(a[23]),.b(b[23]),.bin(bw[23]),.diff(diff[23]),.bout(bw[24]));
    full_subtractor fs24(.a(a[24]),.b(b[24]),.bin(bw[24]),.diff(diff[24]),.bout(bw[25]));
    full_subtractor fs25(.a(a[25]),.b(b[25]),.bin(bw[25]),.diff(diff[25]),.bout(bw[26]));
    full_subtractor fs26(.a(a[26]),.b(b[26]),.bin(bw[26]),.diff(diff[26]),.bout(bw[27]));
    full_subtractor fs27(.a(a[27]),.b(b[27]),.bin(bw[27]),.diff(diff[27]),.bout(bw[28]));
    full_subtractor fs28(.a(a[28]),.b(b[28]),.bin(bw[28]),.diff(diff[28]),.bout(bw[29]));
    full_subtractor fs29(.a(a[29]),.b(b[29]),.bin(bw[29]),.diff(diff[29]),.bout(bw[30]));
    full_subtractor fs30(.a(a[30]),.b(b[30]),.bin(bw[30]),.diff(diff[30]),.bout(bw[31]));
    full_subtractor fs31(.a(a[31]),.b(b[31]),.bin(bw[31]),.diff(diff[31]),.bout(bw[32]));
    assign bout=bw[32];
endmodule

module full_subtractor(input a, input b, input bin, output diff, output bout);
    wire d0, b0, b1;
    assign d0   = a ^ b;
    assign diff = d0 ^ bin;
    assign b0   = (~a) & b;
    assign b1   = (~d0) & bin;
    assign bout = b0 | b1;
endmodule


