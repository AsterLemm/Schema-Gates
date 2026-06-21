// =====================================================================
//  add_carry_increment8.v
//  8-bit carry-increment adder.
//  Behavioral form; lowers to gates in synthesis.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module add_carry_increment8(input [7:0] a, input [7:0] b, input cin, output [7:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define cin input 255.230.80
    // define sum output 120.255.160
    // define cout output 255.120.120
    wire [8:0] s = {1'b0,a} + {1'b0,b} + cin;
    assign sum=s[7:0]; assign cout=s[8];
endmodule


