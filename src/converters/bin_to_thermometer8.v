// =====================================================================
//  bin_to_thermometer8.v
//  8-bit binary->thermometer code.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_thermometer8(input [3:0] n, output [7:0] y);
    // define n input 200.120.255   // define y output 120.255.160
    assign y[0] = (n > 0);
    assign y[1] = (n > 1);
    assign y[2] = (n > 2);
    assign y[3] = (n > 3);
    assign y[4] = (n > 4);
    assign y[5] = (n > 5);
    assign y[6] = (n > 6);
    assign y[7] = (n > 7);
endmodule


