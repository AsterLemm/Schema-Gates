// =====================================================================
//  hamming_encode_12_8.v
//  Hamming SEC encoder (8 data -> 12 bits).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module hamming_encode_12_8(input [7:0] d, output [11:0] code);
    // define d input 80.160.255
    // define code output 120.255.160
    // Hamming SEC code: 8 data + 4 parity = 12 bits.
    integer i, pos, pi; reg [11:0] c; reg [7:0] dd;
    always @(*) begin
        c = 0; dd = d; pos = 0;
        // place data bits into non-power-of-two positions (1-indexed)
        for (i=1;i<=12;i=i+1) begin
            if ((i & (i-1)) != 0) begin c[i-1] = dd[pos]; pos = pos+1; end
        end
        // compute parity bits at power-of-two positions
        for (pi=0;pi<4;pi=pi+1) begin : pgen
            integer mask; reg par; integer j;
            mask = (1<<pi); par=0;
            for (j=1;j<=12;j=j+1) if ((j & mask)!=0 && j!=mask) par = par ^ c[j-1];
            c[mask-1] = par;
        end
    end
    assign code = c;
endmodule


