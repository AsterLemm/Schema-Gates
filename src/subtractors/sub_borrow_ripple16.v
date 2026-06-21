// =====================================================================
//  sub_borrow_ripple16.v
//  16-bit borrow-ripple subtractor (full_subtractor chain).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sub_borrow_ripple16(input [15:0] a, input [15:0] b, input bin, output [15:0] diff, output bout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define bin input 255.230.80
    // define diff output 120.255.160
    // define bout output 255.120.120
    wire [16:0] bw; assign bw[0]=bin;
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
    assign bout=bw[16];
endmodule

module full_subtractor(input a, input b, input bin, output diff, output bout);
    wire d0, b0, b1;
    assign d0   = a ^ b;
    assign diff = d0 ^ bin;
    assign b0   = (~a) & b;
    assign b1   = (~d0) & bin;
    assign bout = b0 | b1;
endmodule


