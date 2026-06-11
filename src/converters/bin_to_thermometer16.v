// =====================================================================
//  bin_to_thermometer16.v
//  16-bit binary->thermometer code.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_thermometer16(input [4:0] n, output [15:0] y);
    // define n input 200.120.255   // define y output 120.255.160
    assign y[0] = (n > 0);
    assign y[1] = (n > 1);
    assign y[2] = (n > 2);
    assign y[3] = (n > 3);
    assign y[4] = (n > 4);
    assign y[5] = (n > 5);
    assign y[6] = (n > 6);
    assign y[7] = (n > 7);
    assign y[8] = (n > 8);
    assign y[9] = (n > 9);
    assign y[10] = (n > 10);
    assign y[11] = (n > 11);
    assign y[12] = (n > 12);
    assign y[13] = (n > 13);
    assign y[14] = (n > 14);
    assign y[15] = (n > 15);
endmodule


