// =====================================================================
//  barrel_bidir32.v
//  32-bit bidirectional barrel shifter.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module barrel_bidir32(input [31:0] a, input [4:0] sh, input dir, output [31:0] y);
    // define a input 80.160.255   // define sh input 200.120.255   // define dir input 200.120.255   // define y output 120.255.160
    // dir=0 left, dir=1 right (logical)
    wire [31:0] l = a << sh;
    wire [31:0] r = a >> sh;
    assign y = dir ? r : l;
endmodule


