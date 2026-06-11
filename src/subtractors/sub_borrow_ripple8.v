// =====================================================================
//  sub_borrow_ripple8.v
//  8-bit borrow-ripple subtractor (full_subtractor chain).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sub_borrow_ripple8(input [7:0] a, input [7:0] b, input bin, output [7:0] diff, output bout);
    // define a input 80.160.255   // define b input 80.200.255   // define bin input 255.230.80
    // define diff output 120.255.160   // define bout output 255.120.120
    wire [8:0] bw; assign bw[0]=bin;
    full_subtractor fs0(.a(a[0]),.b(b[0]),.bin(bw[0]),.diff(diff[0]),.bout(bw[1]));
    full_subtractor fs1(.a(a[1]),.b(b[1]),.bin(bw[1]),.diff(diff[1]),.bout(bw[2]));
    full_subtractor fs2(.a(a[2]),.b(b[2]),.bin(bw[2]),.diff(diff[2]),.bout(bw[3]));
    full_subtractor fs3(.a(a[3]),.b(b[3]),.bin(bw[3]),.diff(diff[3]),.bout(bw[4]));
    full_subtractor fs4(.a(a[4]),.b(b[4]),.bin(bw[4]),.diff(diff[4]),.bout(bw[5]));
    full_subtractor fs5(.a(a[5]),.b(b[5]),.bin(bw[5]),.diff(diff[5]),.bout(bw[6]));
    full_subtractor fs6(.a(a[6]),.b(b[6]),.bin(bw[6]),.diff(diff[6]),.bout(bw[7]));
    full_subtractor fs7(.a(a[7]),.b(b[7]),.bin(bw[7]),.diff(diff[7]),.bout(bw[8]));
    assign bout=bw[8];
endmodule

module full_subtractor(input a, input b, input bin, output diff, output bout);
    wire d0, b0, b1;
    assign d0   = a ^ b;
    assign diff = d0 ^ bin;
    assign b0   = (~a) & b;
    assign b1   = (~d0) & bin;
    assign bout = b0 | b1;
endmodule


