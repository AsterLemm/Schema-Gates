// =====================================================================
//  fp16_add.v
//  fp16 (IEEE half) adder, round-toward-zero, educational.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp16_add(input [15:0] a, input [15:0] b, output reg [15:0] y);
    // define a input 80.160.255
    // define b input 80.200.255
    // define y output 120.255.160
    wire [15:0] bb = b;
    reg sa,sb; reg [4:0] ea,eb; reg [10:0] ma,mb;  // 11-bit incl hidden 1
    reg [4:0] ed; reg signed [6:0] esh;
    reg [12:0] mant_a, mant_b; reg [13:0] sum_m;
    reg signed [5:0] exp_res; reg sign_res; reg [10:0] man_res;
    integer i;
    always @(*) begin
        sa=a[15]; ea=a[14:10]; ma={|ea, a[9:0]};
        sb=bb[15]; eb=bb[14:10]; mb={|eb, bb[9:0]};
        // align exponents
        mant_a = {ma,2'b0}; mant_b={mb,2'b0};   // guard bits
        if (ea>eb) begin exp_res=ea; mant_b = mant_b >> (ea-eb); end
        else begin exp_res=eb; mant_a = mant_a >> (eb-ea); end
        if (sa==sb) begin sum_m = mant_a + mant_b; sign_res=sa; end
        else if (mant_a >= mant_b) begin sum_m = mant_a - mant_b; sign_res=sa; end
        else begin sum_m = mant_b - mant_a; sign_res=sb; end
        // normalize
        if (sum_m==0) begin y=16'b0; end
        else begin
            if (sum_m[13]) begin sum_m = sum_m >> 1; exp_res=exp_res+1; end
            else begin
                for (i=0;i<13;i=i+1) if (!sum_m[12]) begin sum_m=sum_m<<1; exp_res=exp_res-1; end
            end
            man_res = sum_m[12:2];
            if (exp_res<=0) y={sign_res,15'b0};
            else if (exp_res>=31) y={sign_res,5'b11111,10'b0};
            else y={sign_res, exp_res[4:0], man_res[9:0]};
        end
    end
endmodule


