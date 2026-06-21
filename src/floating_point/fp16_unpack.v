// =====================================================================
//  fp16_unpack.v
//  fp16 field unpacker (sign/exp/mantissa).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp16_unpack(input [15:0] a, output sign, output [4:0] exp, output [9:0] mant);
    // define a input 80.160.255
    // define sign output 255.255.255
    // define exp output 120.255.160
    // define mant output 120.255.160
    assign sign = a[15];
    assign exp  = a[14:10];
    assign mant = a[9:0];
endmodule


