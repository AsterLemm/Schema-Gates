// =====================================================================
//  div_nonrestoring_iter16.v
//  16-bit iterative non-restoring divider (16 cycles).
//  Realized via structural per-step subtractor; no / or % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module div_nonrestoring_iter16(input clk, input rst, input start, input [15:0] a, input [15:0] b,
    output reg [15:0] quotient, output reg [15:0] remainder,
    output divide_by_zero, output reg valid, output reg busy, output reg done);
    // define clk input 255.230.80   // define rst input 255.80.80   // define start input 255.180.80
    // define a input 80.160.255   // define b input 80.200.255   // define quotient output 120.255.160
    // define remainder output 120.255.160   // define done output 255.255.255
    reg [15:0] q, dividend, divisor; reg [16:0] rem; reg [4:0] i;
    wire dz_now = ~(|b);
    assign divide_by_zero = dz_now;
    wire [16:0] sh = {rem[15:0], dividend[15]};
    wire [16:0] tr; wire bo;
    divstep_sub17 st(.a(sh), .b({1'b0,divisor}), .diff(tr), .bout(bo));
    wire qbit = ~bo;
    always @(posedge clk) begin
        if (rst) begin busy<=0; done<=0; valid<=0; q<=0; rem<=0; i<=0; quotient<=0; remainder<=0; end
        else if (start) begin
            if (dz_now) begin quotient<={16{1'b1}}; remainder<=a; valid<=0; done<=1; busy<=0; end
            else begin busy<=1; done<=0; valid<=0; dividend<=a; divisor<=b; q<=0; rem<=0; i<=0; end
        end else if (busy) begin
            rem <= qbit ? tr : sh;
            q   <= {q[14:0], qbit};
            dividend <= {dividend[14:0], 1'b0};
            i <= i + 1'b1;
            if (i == 15) begin busy<=0; done<=1; valid<=1;
                quotient  <= {q[14:0], qbit};
                remainder <= (qbit ? tr[15:0] : sh[15:0]); end
        end else done<=0;
    end
endmodule

module divstep_sub17(input [16:0] a, input [16:0] b, output [16:0] diff, output bout);
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


