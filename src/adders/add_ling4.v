// =====================================================================
//  add_ling4.v
//  4-bit Ling-style adder (transmit t=a|b, carry recurrence).
//  MODULAR: one chained bit cell per bit (drillable repeated unit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- add_ling4_cell : one Ling bit cell (p/g/t + sum + carry-out) ---
module add_ling4_cell(input ai, input bi, input ci, output si, output co);
    wire p = ai ^ bi;
    wire g = ai & bi;
    wire t = ai | bi;   // Ling transmit
    assign co = g | (t & ci);
    assign si = p ^ ci;
endmodule

module add_ling4(input [3:0] a, input [3:0] b, input cin, output [3:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define cin input 255.230.80
    // define sum output 120.255.160
    // define cout output 255.120.120
    // 4 chained Ling bit cells (same per-bit equations as before)
    wire [4:0] c; assign c[0]=cin;
    add_ling4_cell u_bit0(.ai(a[0]), .bi(b[0]), .ci(c[0]), .si(sum[0]), .co(c[1]));
    add_ling4_cell u_bit1(.ai(a[1]), .bi(b[1]), .ci(c[1]), .si(sum[1]), .co(c[2]));
    add_ling4_cell u_bit2(.ai(a[2]), .bi(b[2]), .ci(c[2]), .si(sum[2]), .co(c[3]));
    add_ling4_cell u_bit3(.ai(a[3]), .bi(b[3]), .ci(c[3]), .si(sum[3]), .co(c[4]));
    assign cout = c[4];
endmodule


