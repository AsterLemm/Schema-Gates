// =====================================================================
//  fir4_q8_8.v
//  4-tap FIR moving-average filter (Q8.8); coefficient multiply is a shift, no * operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fir4_q8_8(input clk, input rst, input signed [15:0] x, output reg signed [15:0] y);
    // define clk input 255.230.80   // define x input 80.160.255   // define y output 120.255.160
    // 4-tap FIR, Q8.8 coefficients all 0.25 (=64 in Q8.8) -> moving average.
    // coefficient multiply by 64 is a structural left-shift by 6 (no * operator).
    reg signed [15:0] d0,d1,d2,d3;
    wire signed [31:0] xx = $signed({{16{x[15]}},  x})  << 6;
    wire signed [31:0] t0 = $signed({{16{d0[15]}}, d0}) << 6;
    wire signed [31:0] t1 = $signed({{16{d1[15]}}, d1}) << 6;
    wire signed [31:0] t2 = $signed({{16{d2[15]}}, d2}) << 6;
    wire signed [31:0] acc = xx + t0 + t1 + t2;
    always @(posedge clk) begin
        if (rst) begin d0<=0;d1<=0;d2<=0;d3<=0;y<=0; end
        else begin d0<=x; d1<=d0; d2<=d1; d3<=d2; y<=acc>>>8; end
    end
endmodule


