// Golden test: 8-bit Kogge-Stone adder, exhaustive over a,b,cin.
module tb; integer errs=0,i,j,k; reg [7:0] a,b; reg cin; wire [7:0] sum; wire cout;
add_kogge_stone8 u(.a(a),.b(b),.cin(cin),.sum(sum),.cout(cout));
initial begin
 for(i=0;i<256;i=i+1) for(j=0;j<256;j=j+1) for(k=0;k<2;k=k+1) begin
   a=i;b=j;cin=k;#1; if({cout,sum}!==(a+b+k)) errs=errs+1; end
 $display("add_kogge_stone8 exhaustive: %0d errors",errs); end endmodule
