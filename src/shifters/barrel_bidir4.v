// =====================================================================
//  barrel_bidir4.v
//  4-bit bidirectional barrel shifter.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module barrel_bidir4(input [3:0] a, input [1:0] sh, input dir, output [3:0] y);
    // define a input 80.160.255
    // define sh input 200.120.255
    // define dir input 200.120.255
    // define y output 120.255.160
    // dir=0 left, dir=1 right (logical)
    wire [3:0] l = a << sh;
    wire [3:0] r = a >> sh;
    assign y = dir ? r : l;
endmodule


