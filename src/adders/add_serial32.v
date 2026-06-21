// =====================================================================
//  add_serial32.v
//  32-bit bit-serial adder (1 full-adder + carry FF, 32 clocks).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_serial32(input clk, input rst, input start, input [31:0] a, input [31:0] b, output reg [31:0] sum, output reg cout, output reg done);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define start input 255.180.80
    // define a input 80.160.255
    // define b input 80.200.255
    // define sum output 120.255.160
    // define cout output 255.120.120
    // define done output 255.255.255
    reg [5:0] idx;
    reg carry;
    wire bit_sum = a[idx] ^ b[idx] ^ carry;
    wire bit_carry = (a[idx]&b[idx]) | (carry&(a[idx]^b[idx]));
    always @(posedge clk) begin
        if (rst) begin idx<=0; carry<=0; sum<=0; cout<=0; done<=0; end
        else if (start) begin idx<=0; carry<=0; sum<=0; cout<=0; done<=0; end
        else if (!done) begin
            sum[idx] <= bit_sum; carry <= bit_carry;
            if (idx == 31) begin cout <= bit_carry; done <= 1'b1; end
            else idx <= idx + 1'b1;
        end
    end
endmodule


