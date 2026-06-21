// =====================================================================
//  extract_field16.v
//  16-bit extract bitfield (len bits at pos).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module extract_field16(input [15:0] a, input [3:0] pos, input [4:0] len, output [15:0] y);
    // define a input 80.160.255
    // define pos input 200.120.255
    // define len input 200.120.255
    // define y output 120.255.160
    wire [15:0] m = ({16'b1} << len) - 1'b1;
    assign y = (a >> pos) & m;
endmodule


