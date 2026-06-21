// =====================================================================
//  extract_field4.v
//  4-bit extract bitfield (len bits at pos).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module extract_field4(input [3:0] a, input [1:0] pos, input [2:0] len, output [3:0] y);
    // define a input 80.160.255
    // define pos input 200.120.255
    // define len input 200.120.255
    // define y output 120.255.160
    wire [3:0] m = ({4'b1} << len) - 1'b1;
    assign y = (a >> pos) & m;
endmodule


