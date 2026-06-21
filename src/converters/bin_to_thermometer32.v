// =====================================================================
//  bin_to_thermometer32.v
//  32-bit binary->thermometer code.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module bin_to_thermometer32(input [5:0] n, output [31:0] y);
    // define n input 200.120.255
    // define y output 120.255.160
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
    assign y[16] = (n > 16);
    assign y[17] = (n > 17);
    assign y[18] = (n > 18);
    assign y[19] = (n > 19);
    assign y[20] = (n > 20);
    assign y[21] = (n > 21);
    assign y[22] = (n > 22);
    assign y[23] = (n > 23);
    assign y[24] = (n > 24);
    assign y[25] = (n > 25);
    assign y[26] = (n > 26);
    assign y[27] = (n > 27);
    assign y[28] = (n > 28);
    assign y[29] = (n > 29);
    assign y[30] = (n > 30);
    assign y[31] = (n > 31);
endmodule


