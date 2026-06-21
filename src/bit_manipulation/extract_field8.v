// =====================================================================
//  extract_field8.v
//  8-bit extract bitfield (len bits at pos).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module extract_field8(input [7:0] a, input [2:0] pos, input [3:0] len, output [7:0] y);
    // define a input 80.160.255
    // define pos input 200.120.255
    // define len input 200.120.255
    // define y output 120.255.160
    wire [7:0] m = ({8'b1} << len) - 1'b1;
    assign y = (a >> pos) & m;
endmodule


