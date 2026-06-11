// =====================================================================
//  div_restoring_iter32.v
//  32-bit iterative restoring divider (32 cycles).
//  Structural per-step subtractor; no / or % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module div_restoring_iter32(input clk, input rst, input start, input [31:0] a, input [31:0] b,
    output reg [31:0] quotient, output reg [31:0] remainder,
    output divide_by_zero, output reg valid, output reg busy, output reg done);
    // define clk input 255.230.80   // define rst input 255.80.80   // define start input 255.180.80
    // define a input 80.160.255   // define b input 80.200.255   // define quotient output 120.255.160
    // define remainder output 120.255.160   // define done output 255.255.255
    reg [31:0] q, dividend, divisor; reg [32:0] rem; reg [5:0] i;
    wire dz_now = ~(|b);
    assign divide_by_zero = dz_now;
    wire [32:0] sh = {rem[31:0], dividend[31]};
    wire [32:0] tr; wire bo;
    divstep_sub33 st(.a(sh), .b({1'b0,divisor}), .diff(tr), .bout(bo));
    wire qbit = ~bo;
    always @(posedge clk) begin
        if (rst) begin busy<=0; done<=0; valid<=0; q<=0; rem<=0; i<=0; quotient<=0; remainder<=0; end
        else if (start) begin
            if (dz_now) begin quotient<={32{1'b1}}; remainder<=a; valid<=0; done<=1; busy<=0; end
            else begin busy<=1; done<=0; valid<=0; dividend<=a; divisor<=b; q<=0; rem<=0; i<=0; end
        end else if (busy) begin
            rem <= qbit ? tr : sh;
            q   <= {q[30:0], qbit};
            dividend <= {dividend[30:0], 1'b0};
            i <= i + 1'b1;
            if (i == 31) begin busy<=0; done<=1; valid<=1;
                quotient  <= {q[30:0], qbit};
                remainder <= (qbit ? tr[31:0] : sh[31:0]); end
        end else done<=0;
    end
endmodule

module divstep_sub33(input [32:0] a, input [32:0] b, output [32:0] diff, output bout);
    wire [33:0] c; assign c[0]=1'b1;
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
    full_adder fa18(.a(a[18]),.b(~b[18]),.cin(c[18]),.sum(diff[18]),.cout(c[19]));
    full_adder fa19(.a(a[19]),.b(~b[19]),.cin(c[19]),.sum(diff[19]),.cout(c[20]));
    full_adder fa20(.a(a[20]),.b(~b[20]),.cin(c[20]),.sum(diff[20]),.cout(c[21]));
    full_adder fa21(.a(a[21]),.b(~b[21]),.cin(c[21]),.sum(diff[21]),.cout(c[22]));
    full_adder fa22(.a(a[22]),.b(~b[22]),.cin(c[22]),.sum(diff[22]),.cout(c[23]));
    full_adder fa23(.a(a[23]),.b(~b[23]),.cin(c[23]),.sum(diff[23]),.cout(c[24]));
    full_adder fa24(.a(a[24]),.b(~b[24]),.cin(c[24]),.sum(diff[24]),.cout(c[25]));
    full_adder fa25(.a(a[25]),.b(~b[25]),.cin(c[25]),.sum(diff[25]),.cout(c[26]));
    full_adder fa26(.a(a[26]),.b(~b[26]),.cin(c[26]),.sum(diff[26]),.cout(c[27]));
    full_adder fa27(.a(a[27]),.b(~b[27]),.cin(c[27]),.sum(diff[27]),.cout(c[28]));
    full_adder fa28(.a(a[28]),.b(~b[28]),.cin(c[28]),.sum(diff[28]),.cout(c[29]));
    full_adder fa29(.a(a[29]),.b(~b[29]),.cin(c[29]),.sum(diff[29]),.cout(c[30]));
    full_adder fa30(.a(a[30]),.b(~b[30]),.cin(c[30]),.sum(diff[30]),.cout(c[31]));
    full_adder fa31(.a(a[31]),.b(~b[31]),.cin(c[31]),.sum(diff[31]),.cout(c[32]));
    full_adder fa32(.a(a[32]),.b(~b[32]),.cin(c[32]),.sum(diff[32]),.cout(c[33]));
    assign bout = ~c[33];
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


