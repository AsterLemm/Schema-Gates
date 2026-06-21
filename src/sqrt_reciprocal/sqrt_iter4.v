// =====================================================================
//  sqrt_iter4.v
//  4-bit iterative integer square root (digit-by-digit).
//  Sequential; shifts/adds/subtracts only, no *, /, % operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module sqrt_iter4(input clk, input rst, input start, input [3:0] a, output reg [1:0] root, output reg done, output reg busy);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define start input 255.180.80
    // define a input 80.160.255
    // define root output 120.255.160
    // define done output 255.255.255
    reg [3:0] op; reg [3:0] res; reg [3:0] one;
    wire [3:0] ONE_INIT = 4'b1 << (4-2);
    wire [3:0] res_plus_one = res + one;   // add (structural-friendly)
    always @(posedge clk) begin
        if (rst) begin busy<=0; done<=0; root<=0; end
        else if (start) begin op<=a; res<=0; one<=ONE_INIT; busy<=1; done<=0; end
        else if (busy) begin
            if (one == 0) begin busy<=0; done<=1; root<=res[1:0]; end
            else begin
                if (op >= res_plus_one) begin op <= op - res_plus_one; res <= (res >> 1) + one; end
                else res <= res >> 1;
                one <= one >> 2;
            end
        end else done<=0;
    end
endmodule


