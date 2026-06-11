// =====================================================================
//  addsub_rc4.v
//  4-bit add/sub on ripple adder (sub=1 -> a-b via b^1,cin=1).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module addsub_rc4(input [3:0] a, input [3:0] b, input sub, output [3:0] result, output cout, output ovf);
    // define a input 80.160.255   // define b input 80.200.255   // define sub input 200.120.255
    // define result output 120.255.160   // define cout output 255.120.120   // define ovf output 255.255.255
    wire [3:0] bx = b ^ {4{sub}};
    wire co;
    rcadd4 u(.a(a), .b(bx), .cin(sub), .sum(result), .cout(co));
    assign cout = co;
    assign ovf  = (a[3]==bx[3]) & (result[3]!=a[3]);
endmodule

module rcadd4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    wire [4:0] c; assign c[0]=cin;
    full_adder fa0(.a(a[0]),.b(b[0]),.cin(c[0]),.sum(sum[0]),.cout(c[1]));
    full_adder fa1(.a(a[1]),.b(b[1]),.cin(c[1]),.sum(sum[1]),.cout(c[2]));
    full_adder fa2(.a(a[2]),.b(b[2]),.cin(c[2]),.sum(sum[2]),.cout(c[3]));
    full_adder fa3(.a(a[3]),.b(b[3]),.cin(c[3]),.sum(sum[3]),.cout(c[4]));
    assign cout=c[4];
endmodule

module full_adder(input a, input b, input cin, output sum, output cout);
    wire s0, c0, c1;
    half_adder ha0(.a(a),  .b(b),   .sum(s0),  .carry(c0));
    half_adder ha1(.a(s0), .b(cin), .sum(sum), .carry(c1));
    assign cout = c0 | c1;
endmodule

module half_adder(input a, input b, output sum, output carry);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule


