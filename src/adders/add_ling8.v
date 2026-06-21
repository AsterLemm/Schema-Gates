// =====================================================================
//  add_ling8.v
//  8-bit Ling-style adder (transmit t=a|b, carry recurrence).
//  MODULAR: one chained bit cell per bit (drillable repeated unit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- add_ling8_cell : one Ling bit cell (p/g/t + sum + carry-out) ---
module add_ling8_cell(input ai, input bi, input ci, output si, output co);
    wire p = ai ^ bi;
    wire g = ai & bi;
    wire t = ai | bi;   // Ling transmit
    assign co = g | (t & ci);
    assign si = p ^ ci;
endmodule

module add_ling8(input [7:0] a, input [7:0] b, input cin, output [7:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define cin input 255.230.80
    // define sum output 120.255.160
    // define cout output 255.120.120
    // 8 chained Ling bit cells (same per-bit equations as before)
    wire [8:0] c; assign c[0]=cin;
    add_ling8_cell u_bit0(.ai(a[0]), .bi(b[0]), .ci(c[0]), .si(sum[0]), .co(c[1]));
    add_ling8_cell u_bit1(.ai(a[1]), .bi(b[1]), .ci(c[1]), .si(sum[1]), .co(c[2]));
    add_ling8_cell u_bit2(.ai(a[2]), .bi(b[2]), .ci(c[2]), .si(sum[2]), .co(c[3]));
    add_ling8_cell u_bit3(.ai(a[3]), .bi(b[3]), .ci(c[3]), .si(sum[3]), .co(c[4]));
    add_ling8_cell u_bit4(.ai(a[4]), .bi(b[4]), .ci(c[4]), .si(sum[4]), .co(c[5]));
    add_ling8_cell u_bit5(.ai(a[5]), .bi(b[5]), .ci(c[5]), .si(sum[5]), .co(c[6]));
    add_ling8_cell u_bit6(.ai(a[6]), .bi(b[6]), .ci(c[6]), .si(sum[6]), .co(c[7]));
    add_ling8_cell u_bit7(.ai(a[7]), .bi(b[7]), .ci(c[7]), .si(sum[7]), .co(c[8]));
    assign cout = c[8];
endmodule


