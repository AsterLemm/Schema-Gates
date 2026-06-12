// =====================================================================
//  add_ling16.v
//  16-bit Ling-style adder (transmit t=a|b, carry recurrence).
//  MODULAR: one chained bit cell per bit (drillable repeated unit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- add_ling16_cell : one Ling bit cell (p/g/t + sum + carry-out) ---
module add_ling16_cell(input ai, input bi, input ci, output si, output co);
    wire p = ai ^ bi;
    wire g = ai & bi;
    wire t = ai | bi;   // Ling transmit
    assign co = g | (t & ci);
    assign si = p ^ ci;
endmodule

module add_ling16(input [15:0] a, input [15:0] b, input cin, output [15:0] sum, output cout);
    // define a input 80.160.255   // define b input 80.200.255
    // define cin input 255.230.80   // define sum output 120.255.160   // define cout output 255.120.120
    // 16 chained Ling bit cells (same per-bit equations as before)
    wire [16:0] c; assign c[0]=cin;
    add_ling16_cell u_bit0(.ai(a[0]), .bi(b[0]), .ci(c[0]), .si(sum[0]), .co(c[1]));
    add_ling16_cell u_bit1(.ai(a[1]), .bi(b[1]), .ci(c[1]), .si(sum[1]), .co(c[2]));
    add_ling16_cell u_bit2(.ai(a[2]), .bi(b[2]), .ci(c[2]), .si(sum[2]), .co(c[3]));
    add_ling16_cell u_bit3(.ai(a[3]), .bi(b[3]), .ci(c[3]), .si(sum[3]), .co(c[4]));
    add_ling16_cell u_bit4(.ai(a[4]), .bi(b[4]), .ci(c[4]), .si(sum[4]), .co(c[5]));
    add_ling16_cell u_bit5(.ai(a[5]), .bi(b[5]), .ci(c[5]), .si(sum[5]), .co(c[6]));
    add_ling16_cell u_bit6(.ai(a[6]), .bi(b[6]), .ci(c[6]), .si(sum[6]), .co(c[7]));
    add_ling16_cell u_bit7(.ai(a[7]), .bi(b[7]), .ci(c[7]), .si(sum[7]), .co(c[8]));
    add_ling16_cell u_bit8(.ai(a[8]), .bi(b[8]), .ci(c[8]), .si(sum[8]), .co(c[9]));
    add_ling16_cell u_bit9(.ai(a[9]), .bi(b[9]), .ci(c[9]), .si(sum[9]), .co(c[10]));
    add_ling16_cell u_bit10(.ai(a[10]), .bi(b[10]), .ci(c[10]), .si(sum[10]), .co(c[11]));
    add_ling16_cell u_bit11(.ai(a[11]), .bi(b[11]), .ci(c[11]), .si(sum[11]), .co(c[12]));
    add_ling16_cell u_bit12(.ai(a[12]), .bi(b[12]), .ci(c[12]), .si(sum[12]), .co(c[13]));
    add_ling16_cell u_bit13(.ai(a[13]), .bi(b[13]), .ci(c[13]), .si(sum[13]), .co(c[14]));
    add_ling16_cell u_bit14(.ai(a[14]), .bi(b[14]), .ci(c[14]), .si(sum[14]), .co(c[15]));
    add_ling16_cell u_bit15(.ai(a[15]), .bi(b[15]), .ci(c[15]), .si(sum[15]), .co(c[16]));
    assign cout = c[16];
endmodule


