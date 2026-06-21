// =====================================================================
//  counter_updown4.v
//  4-bit up/down counter.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module counter_updown4(input clk, input rst, input en, input up, output reg [3:0] q);
    // define clk input 255.230.80
    // define rst input 255.80.80
    // define en input 255.180.80
    // define up input 200.120.255
    // define q output 120.255.160
    always @(posedge clk) if (rst) q<=4'b0; else if (en) q<= up ? q+1'b1 : q-1'b1;
endmodule


