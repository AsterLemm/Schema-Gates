// Golden test: 8-bit structural barrel left shifter.
module tb; integer errs=0,i,s; reg [7:0] a; reg [2:0] sh; wire [7:0] y;
barrel_left8 u(.a(a),.sh(sh),.y(y));
initial begin for(i=0;i<256;i=i+1) for(s=0;s<8;s=s+1) begin a=i;sh=s;#1;
  if(y!==((a<<s)&8'hFF)) errs=errs+1; end
 $display("barrel_left8 exhaustive: %0d errors",errs); end endmodule
