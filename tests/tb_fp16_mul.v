// Golden test: fp16 multiply vs real-valued reference (relative error < 2%).
module tb; integer i,errs; reg [15:0] a,b; wire [15:0] y;
fp16_mul u(.a(a),.b(b),.y(y));
function real f16; input [15:0] v; real m; integer e,k; begin
 if (v[14:10]==0) f16=0.0; else begin m=1.0; for(k=0;k<10;k=k+1) if(v[k]) m=m+(2.0**(k-10));
 e=v[14:10]-15; f16=m*(2.0**e); if(v[15]) f16=-f16; end end endfunction
real ga,gb,gy,gp,re;
initial begin errs=0;
 for(i=0;i<3000;i=i+1) begin
   a={$random}&16'h7FFF; a[14:10]=8+({$random}%12);
   b={$random}&16'h7FFF; b[14:10]=8+({$random}%12);
   a[15]=$random; b[15]=$random; #1;
   ga=f16(a); gb=f16(b); gy=f16(y); gp=ga*gb;
   if(gp!=0.0) begin re=(gy-gp)/gp; if(re<0)re=-re; if(re>0.02) errs=errs+1; end
 end
 $display("fp16_mul (3000 normalized): %0d errors",errs); end endmodule
