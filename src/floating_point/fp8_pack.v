// =====================================================================
//  fp8_pack.v
//  fp8 field packer.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp8_pack(input sign, input [3:0] exp, input [2:0] mant, output [7:0] a);
    // define sign input 200.120.255   // define exp input 80.160.255   // define mant input 80.200.255   // define a output 120.255.160
    assign a = {sign, exp, mant};
endmodule


