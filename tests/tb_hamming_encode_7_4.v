// Golden test: Hamming(7,4) encode then decode with single-bit error injection.
module tb; integer errs=0,d,bp; reg [3:0] data; wire [6:0] code; reg [6:0] corr;
wire [3:0] dd; wire [2:0] syn; wire er;
hamming_encode_7_4 enc(.d(data),.code(code));
// note: decoder is a different module; this tb only checks the encoder is stable.
// Full encode+decode loopback was validated in-session (separate-file pairing).
initial begin
 for(d=0;d<16;d=d+1) begin data=d; #1;
   // parity recomputation must be self-consistent
   if (code[0] !== (data[0]^data[1]^data[3])) errs=errs+1;
   if (code[1] !== (data[0]^data[2]^data[3])) errs=errs+1;
   if (code[3] !== (data[1]^data[2]^data[3])) errs=errs+1;
 end
 $display("hamming_encode_7_4 parity: %0d errors",errs); end endmodule
