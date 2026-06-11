// Golden test: 4x4 array multiplier, exhaustive.
module tb; integer errs=0,i,j; reg [3:0] a,b; wire [7:0] p;
mul_array4 u(.a(a),.b(b),.product(p));
initial begin for(i=0;i<16;i=i+1) for(j=0;j<16;j=j+1) begin a=i;b=j;#1;
  if(p!==(a*b)) errs=errs+1; end
 $display("mul_array4 exhaustive: %0d errors",errs); end endmodule
