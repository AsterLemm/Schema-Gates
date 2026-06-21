// =====================================================================
//  fp8_unpack.v
//  fp8 field unpacker (sign/exp/mantissa).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp8_unpack(input [7:0] a, output sign, output [3:0] exp, output [2:0] mant);
    // define a input 80.160.255
    // define sign output 255.255.255
    // define exp output 120.255.160
    // define mant output 120.255.160
    assign sign = a[7];
    assign exp  = a[6:3];
    assign mant = a[2:0];
endmodule


