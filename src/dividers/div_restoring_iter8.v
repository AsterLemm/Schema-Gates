// =====================================================================
//  div_restoring_iter8.v
//  8-bit iterative restoring divider (8 cycles).
//  Structural per-step subtractor; no / or % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module div_restoring_iter8(input clk, input rst, input start, input [7:0] a, input [7:0] b,
    output reg [7:0] quotient, output reg [7:0] remainder,
    output divide_by_zero, output reg valid, output reg busy, output reg done);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define start input 255.180.80
    // define a input 80.160.255
    // define b input 80.200.255
    // define quotient output 120.255.160
    // define remainder output 120.255.160
    // define done output 255.255.255
    reg [7:0] q, dividend, divisor; reg [8:0] rem; reg [3:0] i;
    wire dz_now = ~(|b);
    assign divide_by_zero = dz_now;
    wire [8:0] sh = {rem[7:0], dividend[7]};
    wire [8:0] tr; wire bo;
    divstep_sub9 st(.a(sh), .b({1'b0,divisor}), .diff(tr), .bout(bo));
    wire qbit = ~bo;
    always @(posedge clk) begin
        if (rst) begin busy<=0; done<=0; valid<=0; q<=0; rem<=0; i<=0; quotient<=0; remainder<=0; end
        else if (start) begin
            if (dz_now) begin quotient<={8{1'b1}}; remainder<=a; valid<=0; done<=1; busy<=0; end
            else begin busy<=1; done<=0; valid<=0; dividend<=a; divisor<=b; q<=0; rem<=0; i<=0; end
        end else if (busy) begin
            rem <= qbit ? tr : sh;
            q   <= {q[6:0], qbit};
            dividend <= {dividend[6:0], 1'b0};
            i <= i + 1'b1;
            if (i == 7) begin busy<=0; done<=1; valid<=1;
                quotient  <= {q[6:0], qbit};
                remainder <= (qbit ? tr[7:0] : sh[7:0]); end
        end else done<=0;
    end
endmodule

module divstep_sub9(input [8:0] a, input [8:0] b, output [8:0] diff, output bout);
    wire [9:0] c; assign c[0]=1'b1;
    full_adder fa0(.a(a[0]),.b(~b[0]),.cin(c[0]),.sum(diff[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(~b[1]),.cin(c[1]),.sum(diff[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(~b[2]),.cin(c[2]),.sum(diff[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(~b[3]),.cin(c[3]),.sum(diff[3]),.cout(c[4]));
    full_adder fa4(.a(a[4]),.b(~b[4]),.cin(c[4]),.sum(diff[4]),.cout(c[5]));
    full_adder fa5(.a(a[5]),.b(~b[5]),.cin(c[5]),.sum(diff[5]),.cout(c[6]));
    full_adder fa6(.a(a[6]),.b(~b[6]),.cin(c[6]),.sum(diff[6]),.cout(c[7]));
    full_adder fa7(.a(a[7]),.b(~b[7]),.cin(c[7]),.sum(diff[7]),.cout(c[8]));
    full_adder fa8(.a(a[8]),.b(~b[8]),.cin(c[8]),.sum(diff[8]),.cout(c[9]));
    assign bout = ~c[9];
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


