// =====================================================================
//  hamming_encode_21_16.v
//  Hamming SEC encoder (16 data -> 21 bits).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module hamming_encode_21_16(input [15:0] d, output [20:0] code);
    // define d input 80.160.255
    // define code output 120.255.160
    // Hamming SEC code: 16 data + 5 parity = 21 bits.
    integer i, pos, pi; reg [20:0] c; reg [15:0] dd;
    always @(*) begin
        c = 0; dd = d; pos = 0;
        // place data bits into non-power-of-two positions (1-indexed)
        for (i=1;i<=21;i=i+1) begin
            if ((i & (i-1)) != 0) begin c[i-1] = dd[pos]; pos = pos+1; end
        end
        // compute parity bits at power-of-two positions
        for (pi=0;pi<5;pi=pi+1) begin : pgen
            integer mask; reg par; integer j;
            mask = (1<<pi); par=0;
            for (j=1;j<=21;j=j+1) if ((j & mask)!=0 && j!=mask) par = par ^ c[j-1];
            c[mask-1] = par;
        end
    end
    assign code = c;
endmodule


