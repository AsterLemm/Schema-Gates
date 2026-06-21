// =====================================================================
//  reciprocal_seed4.v
//  4-bit reciprocal seed (structural leading-one reflect); no arithmetic operator.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

// --- reciprocal_seed4_lead : leading-one detector (one-hot ms[k]) ---
module reciprocal_seed4_lead(input [3:0] a, output [3:0] ms);
    assign ms[0] = a[0] & ~(a[1] | a[2] | a[3]);   // a[0] is the leading one
    assign ms[1] = a[1] & ~(a[2] | a[3]);   // a[1] is the leading one
    assign ms[2] = a[2] & ~(a[3]);   // a[2] is the leading one
    assign ms[3] = a[3] & ~(1'b0);   // a[3] is the leading one
endmodule

module reciprocal_seed4(input [3:0] a, output [3:0] seed);
    // define a input 80.160.255
    // define seed output 120.255.160
    // seed = 2^(W-1-msb(a)) : reflect leading-one position (priority logic)
    wire [3:0] ms;
    reciprocal_seed4_lead u_lead(.a(a), .ms(ms));
    assign seed = {ms[0], ms[1], ms[2], ms[3]};
endmodule


