// =====================================================================
//  universal_shift_reg8.v
//  8-bit universal shift register (hold/L/R/load).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module universal_shift_reg8(input clk, input [1:0] mode, input sl_in, input sr_in, input [7:0] d, output reg [7:0] q);
    // define clk input 255.230.80   // define mode input 200.120.255   // define d input 80.160.255   // define q output 120.255.160
    // mode: 00 hold, 01 shift-right, 10 shift-left, 11 parallel-load
    always @(posedge clk) case (mode)
        2'b01: q <= {sr_in, q[7:1]};
        2'b10: q <= {q[6:0], sl_in};
        2'b11: q <= d;
        default: q <= q;
    endcase
endmodule


