// =====================================================================
//  fp16_normalize.v
//  fp16 mantissa normalizer (leading-1 alignment).
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp16_normalize(input [13:0] mant_in, input signed [6:0] exp_in, output reg [9:0] mant_out, output reg [4:0] exp_out);
    // define mant_in input 80.160.255   // define exp_in input 80.200.255   // define mant_out output 120.255.160
    reg [13:0] m; reg signed [6:0] e; integer i;
    always @(*) begin m=mant_in; e=exp_in;
        if (m!=0) begin
            for (i=0;i<13;i=i+1) if (!m[13]) begin m=m<<1; e=e-1; end
        end
        mant_out=m[12:3]; exp_out=(e<0)?5'b0:e[4:0];
    end
endmodule


