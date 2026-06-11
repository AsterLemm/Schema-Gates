// =====================================================================
//  bin_to_thermometer4.v
//  4-bit binary->thermometer code.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_thermometer4(input [2:0] n, output [3:0] y);
    // define n input 200.120.255   // define y output 120.255.160
    assign y[0] = (n > 0);
    assign y[1] = (n > 1);
    assign y[2] = (n > 2);
    assign y[3] = (n > 3);
endmodule


