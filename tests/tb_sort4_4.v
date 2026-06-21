// Golden test: 4-input sorting network produces ascending output.
module tb; integer errs=0,i0,i1,i2,i3; reg [3:0] a,b,c,d; wire [3:0] o0,o1,o2,o3;
sort4_4 u(.in0(a),.in1(b),.in2(c),.in3(d),.out0(o0),.out1(o1),.out2(o2),.out3(o3));
initial begin
 for(i0=0;i0<6;i0=i0+1)for(i1=0;i1<6;i1=i1+1)for(i2=0;i2<6;i2=i2+1)for(i3=0;i3<6;i3=i3+1)begin
   a=i0;b=i1;c=i2;d=i3;#1;
   if(!(o0<=o1 && o1<=o2 && o2<=o3)) errs=errs+1; end
 $display("sort4_4 ascending: %0d errors",errs); end endmodule
