// =====================================================================
//  bcd_nines_complement2.v
//  2-digit BCD nine's complement.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_nines_complement2(input [7:0] a, output [7:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y[3:0] = 4'd9 - a[3:0];
    assign y[7:4] = 4'd9 - a[7:4];
endmodule


