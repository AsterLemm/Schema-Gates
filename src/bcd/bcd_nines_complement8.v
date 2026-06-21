// =====================================================================
//  bcd_nines_complement8.v
//  8-digit BCD nine's complement.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bcd_nines_complement8(input [31:0] a, output [31:0] y);
    // define a input 80.160.255
    // define y output 120.255.160
    assign y[3:0] = 4'd9 - a[3:0];
    assign y[7:4] = 4'd9 - a[7:4];
    assign y[11:8] = 4'd9 - a[11:8];
    assign y[15:12] = 4'd9 - a[15:12];
    assign y[19:16] = 4'd9 - a[19:16];
    assign y[23:20] = 4'd9 - a[23:20];
    assign y[27:24] = 4'd9 - a[27:24];
    assign y[31:28] = 4'd9 - a[31:28];
endmodule


