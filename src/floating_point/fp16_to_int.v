// =====================================================================
//  fp16_to_int.v
//  fp16 -> signed int16 (truncating).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp16_to_int(input [15:0] a, output reg signed [15:0] n);
    // define a input 80.160.255
    // define n output 120.255.160
    reg sign; reg [4:0] e; reg [10:0] m; reg [15:0] val; integer sh;
    always @(*) begin
        sign=a[15]; e=a[14:10]; m={|e,a[9:0]};
        if (e==0) n=0;
        else begin
            sh = e - 15 - 10;   // shift of mantissa to integer
            if (sh>=0) val = m << sh; else val = m >> (-sh);
            n = sign ? (~val+1) : val;
        end
    end
endmodule


