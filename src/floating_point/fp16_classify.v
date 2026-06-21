// =====================================================================
//  fp16_classify.v
//  fp16 value classifier (zero/inf/nan/denormal).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp16_classify(input [15:0] a, output is_zero, output is_inf, output is_nan, output is_denormal);
    // define a input 80.160.255
    // define is_zero output 255.255.255
    // define is_inf output 255.255.255
    // define is_nan output 255.255.255
    wire [4:0] exp = a[14:10];
    wire [9:0] man = a[9:0];
    wire exp_all1 = &exp;
    wire exp_all0 = ~|exp;
    assign is_zero     = exp_all0 & ~|man;
    assign is_inf      = exp_all1 & ~|man;
    assign is_nan      = exp_all1 &  |man;
    assign is_denormal = exp_all0 &  |man;
endmodule


