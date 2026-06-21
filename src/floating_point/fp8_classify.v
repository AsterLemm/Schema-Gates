// =====================================================================
//  fp8_classify.v
//  fp8 value classifier (zero/inf/nan/denormal).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp8_classify(input [7:0] a, output is_zero, output is_inf, output is_nan, output is_denormal);
    // define a input 80.160.255
    // define is_zero output 255.255.255
    // define is_inf output 255.255.255
    // define is_nan output 255.255.255
    wire [3:0] exp = a[6:3];
    wire [2:0] man = a[2:0];
    wire exp_all1 = &exp;
    wire exp_all0 = ~|exp;
    assign is_zero     = exp_all0 & ~|man;
    assign is_inf      = exp_all1 & ~|man;
    assign is_nan      = exp_all1 &  |man;
    assign is_denormal = exp_all0 &  |man;
endmodule


