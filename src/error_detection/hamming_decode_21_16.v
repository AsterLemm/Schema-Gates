// =====================================================================
//  hamming_decode_21_16.v
//  Hamming SEC decoder (21 bits -> 16 data, 1-bit correct).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module hamming_decode_21_16(input [20:0] code, output [15:0] d, output error);
    // define code input 80.160.255
    // define d output 120.255.160
    // define error output 255.120.120
    integer pi, j, pos, i; reg [5:0] syn; reg [20:0] corr; reg [15:0] dd;
    always @(*) begin
        syn=0;
        for (pi=0;pi<5;pi=pi+1) begin : sgen
            integer mask; reg par;
            mask=(1<<pi); par=0;
            for (j=1;j<=21;j=j+1) if ((j & mask)!=0) par = par ^ code[j-1];
            syn[pi]=par;
        end
        corr = code;
        if (syn!=0 && syn<=21) corr[syn-1] = ~corr[syn-1];
        dd=0; pos=0;
        for (i=1;i<=21;i=i+1) if ((i & (i-1))!=0) begin dd[pos]=corr[i-1]; pos=pos+1; end
    end
    assign d = dd; assign error = |syn;
endmodule


