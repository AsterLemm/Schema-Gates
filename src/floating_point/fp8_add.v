// =====================================================================
//  fp8_add.v
//  fp8 (E4M3) adder, educational.
//  Part of schema-gates by BITFries.
//  Self-contained: embeds every submodule it uses, down to leaf gates.
//  Target synthesizer: BITF-Synthesis Engine (Verilog -> SchemaGates).
// =====================================================================

module fp8_add(input [7:0] a, input [7:0] b, output reg [7:0] y);
    // define a input 80.160.255
    // define b input 80.200.255
    // define y output 120.255.160
    reg sa,sb; reg [3:0] ea,eb; reg [3:0] ma,mb;  // 4-bit incl hidden 1 (3 mantissa)
    reg [6:0] mant_a,mant_b,sum_m; reg signed [5:0] exp_res; reg sign_res; integer i;
    always @(*) begin
        sa=a[7]; ea=a[6:3]; ma={|ea,a[2:0]};
        sb=b[7]; eb=b[6:3]; mb={|eb,b[2:0]};
        mant_a={ma,3'b0}; mant_b={mb,3'b0};
        if (ea>eb) begin exp_res=ea; mant_b=mant_b>>(ea-eb); end
        else begin exp_res=eb; mant_a=mant_a>>(eb-ea); end
        if (sa==sb) begin sum_m=mant_a+mant_b; sign_res=sa; end
        else if (mant_a>=mant_b) begin sum_m=mant_a-mant_b; sign_res=sa; end
        else begin sum_m=mant_b-mant_a; sign_res=sb; end
        if (sum_m==0) y=8'b0;
        else begin
            if (sum_m[6]) begin sum_m=sum_m>>1; exp_res=exp_res+1; end
            else for (i=0;i<6;i=i+1) if (!sum_m[5]) begin sum_m=sum_m<<1; exp_res=exp_res-1; end
            if (exp_res<=0) y={sign_res,7'b0};
            else if (exp_res>=15) y={sign_res,4'b1111,3'b0};
            else y={sign_res,exp_res[3:0],sum_m[4:2]};
        end
    end
endmodule


