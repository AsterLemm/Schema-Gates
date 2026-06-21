// =====================================================================
//  add_ling32.v
//  32-bit Ling-style adder (transmit t=a|b, carry recurrence).
//  MODULAR: one chained bit cell per bit (drillable repeated unit).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- add_ling32_cell : one Ling bit cell (p/g/t + sum + carry-out) ---
module add_ling32_cell(input ai, input bi, input ci, output si, output co);
    wire p = ai ^ bi;
    wire g = ai & bi;
    wire t = ai | bi;   // Ling transmit
    assign co = g | (t & ci);
    assign si = p ^ ci;
endmodule

module add_ling32(input [31:0] a, input [31:0] b, input cin, output [31:0] sum, output cout);
    // define a input 80.160.255
    // define b input 80.200.255
    // define cin input 255.230.80
    // define sum output 120.255.160
    // define cout output 255.120.120
    // 32 chained Ling bit cells (same per-bit equations as before)
    wire [32:0] c; assign c[0]=cin;
    add_ling32_cell u_bit0(.ai(a[0]), .bi(b[0]), .ci(c[0]), .si(sum[0]), .co(c[1]));
    add_ling32_cell u_bit1(.ai(a[1]), .bi(b[1]), .ci(c[1]), .si(sum[1]), .co(c[2]));
    add_ling32_cell u_bit2(.ai(a[2]), .bi(b[2]), .ci(c[2]), .si(sum[2]), .co(c[3]));
    add_ling32_cell u_bit3(.ai(a[3]), .bi(b[3]), .ci(c[3]), .si(sum[3]), .co(c[4]));
    add_ling32_cell u_bit4(.ai(a[4]), .bi(b[4]), .ci(c[4]), .si(sum[4]), .co(c[5]));
    add_ling32_cell u_bit5(.ai(a[5]), .bi(b[5]), .ci(c[5]), .si(sum[5]), .co(c[6]));
    add_ling32_cell u_bit6(.ai(a[6]), .bi(b[6]), .ci(c[6]), .si(sum[6]), .co(c[7]));
    add_ling32_cell u_bit7(.ai(a[7]), .bi(b[7]), .ci(c[7]), .si(sum[7]), .co(c[8]));
    add_ling32_cell u_bit8(.ai(a[8]), .bi(b[8]), .ci(c[8]), .si(sum[8]), .co(c[9]));
    add_ling32_cell u_bit9(.ai(a[9]), .bi(b[9]), .ci(c[9]), .si(sum[9]), .co(c[10]));
    add_ling32_cell u_bit10(.ai(a[10]), .bi(b[10]), .ci(c[10]), .si(sum[10]), .co(c[11]));
    add_ling32_cell u_bit11(.ai(a[11]), .bi(b[11]), .ci(c[11]), .si(sum[11]), .co(c[12]));
    add_ling32_cell u_bit12(.ai(a[12]), .bi(b[12]), .ci(c[12]), .si(sum[12]), .co(c[13]));
    add_ling32_cell u_bit13(.ai(a[13]), .bi(b[13]), .ci(c[13]), .si(sum[13]), .co(c[14]));
    add_ling32_cell u_bit14(.ai(a[14]), .bi(b[14]), .ci(c[14]), .si(sum[14]), .co(c[15]));
    add_ling32_cell u_bit15(.ai(a[15]), .bi(b[15]), .ci(c[15]), .si(sum[15]), .co(c[16]));
    add_ling32_cell u_bit16(.ai(a[16]), .bi(b[16]), .ci(c[16]), .si(sum[16]), .co(c[17]));
    add_ling32_cell u_bit17(.ai(a[17]), .bi(b[17]), .ci(c[17]), .si(sum[17]), .co(c[18]));
    add_ling32_cell u_bit18(.ai(a[18]), .bi(b[18]), .ci(c[18]), .si(sum[18]), .co(c[19]));
    add_ling32_cell u_bit19(.ai(a[19]), .bi(b[19]), .ci(c[19]), .si(sum[19]), .co(c[20]));
    add_ling32_cell u_bit20(.ai(a[20]), .bi(b[20]), .ci(c[20]), .si(sum[20]), .co(c[21]));
    add_ling32_cell u_bit21(.ai(a[21]), .bi(b[21]), .ci(c[21]), .si(sum[21]), .co(c[22]));
    add_ling32_cell u_bit22(.ai(a[22]), .bi(b[22]), .ci(c[22]), .si(sum[22]), .co(c[23]));
    add_ling32_cell u_bit23(.ai(a[23]), .bi(b[23]), .ci(c[23]), .si(sum[23]), .co(c[24]));
    add_ling32_cell u_bit24(.ai(a[24]), .bi(b[24]), .ci(c[24]), .si(sum[24]), .co(c[25]));
    add_ling32_cell u_bit25(.ai(a[25]), .bi(b[25]), .ci(c[25]), .si(sum[25]), .co(c[26]));
    add_ling32_cell u_bit26(.ai(a[26]), .bi(b[26]), .ci(c[26]), .si(sum[26]), .co(c[27]));
    add_ling32_cell u_bit27(.ai(a[27]), .bi(b[27]), .ci(c[27]), .si(sum[27]), .co(c[28]));
    add_ling32_cell u_bit28(.ai(a[28]), .bi(b[28]), .ci(c[28]), .si(sum[28]), .co(c[29]));
    add_ling32_cell u_bit29(.ai(a[29]), .bi(b[29]), .ci(c[29]), .si(sum[29]), .co(c[30]));
    add_ling32_cell u_bit30(.ai(a[30]), .bi(b[30]), .ci(c[30]), .si(sum[30]), .co(c[31]));
    add_ling32_cell u_bit31(.ai(a[31]), .bi(b[31]), .ci(c[31]), .si(sum[31]), .co(c[32]));
    assign cout = c[32];
endmodule


