// =====================================================================
//  int_to_fp16.v
//  signed int16 -> fp16 conversion.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module int_to_fp16(input signed [15:0] n, output reg [15:0] y);
    // define n input 80.160.255   // define y output 120.255.160
    reg sign; reg [15:0] mag; reg [4:0] e; reg [15:0] m; integer i;
    always @(*) begin
        if (n==0) y=16'b0;
        else begin
            sign=n[15]; mag = n[15] ? (~n+1) : n;
            e=15+15; // start exp guess (bias + 15 max shift)
            // find MSB position
            m=mag;
            for (i=0;i<16;i=i+1) if (!m[15]) begin m=m<<1; e=e-1; end
            // m[15] is hidden 1; mantissa = next 10 bits
            y={sign, e, m[14:5]};
        end
    end
endmodule


