// =====================================================================
//  bcd_nines_complement1.v
//  1-digit BCD nine's complement.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_nines_complement1(input [3:0] a, output [3:0] y);
    // define a input 80.160.255   // define y output 120.255.160
    assign y[3:0] = 4'd9 - a[3:0];
endmodule


