// Golden test: 8-bit Kogge-Stone subtractor.
module tb; integer errs=0,i,j; reg [7:0] a,b; wire [7:0] diff; wire bout;
sub_prefix_kogge_stone8 u(.a(a),.b(b),.diff(diff),.bout(bout));
initial begin
 for(i=0;i<256;i=i+1) for(j=0;j<256;j=j+1) begin a=i;b=j;#1;
   if(diff!==((a-b)&8'hFF)) errs=errs+1; if(bout!==(a<b)) errs=errs+1; end
 $display("sub_prefix_kogge_stone8 exhaustive: %0d errors",errs); end endmodule
