`timescale 1ns/1ps
module tb;
  integer errs = 0;
  reg a, b, cin;
  wire y_not_nand;       not_using_nand        u_notn(.a(a), .y(y_not_nand));
  wire y_and_nand;       and_using_nand        u_andn(.a(a), .b(b), .y(y_and_nand));
  wire y_or_nand;        or_using_nand         u_orn (.a(a), .b(b), .y(y_or_nand));
  wire y_xor_nand;       xor_using_nand        u_xorn(.a(a), .b(b), .y(y_xor_nand));
  wire ha_s_n, ha_c_n;   half_adder_using_nand u_han(.a(a), .b(b), .sum(ha_s_n), .carry(ha_c_n));
  wire fa_s_n, fa_c_n;   full_adder_using_nand u_fan(.a(a), .b(b), .cin(cin), .sum(fa_s_n), .cout(fa_c_n));
  wire y_not_nor;        not_using_nor         u_notr(.a(a), .y(y_not_nor));
  wire y_and_nor;        and_using_nor         u_andr(.a(a), .b(b), .y(y_and_nor));
  wire y_or_nor;         or_using_nor          u_orr (.a(a), .b(b), .y(y_or_nor));
  wire y_xor_nor;        xor_using_nor         u_xorr(.a(a), .b(b), .y(y_xor_nor));
  wire ha_s_r, ha_c_r;   half_adder_using_nor  u_har(.a(a), .b(b), .sum(ha_s_r), .carry(ha_c_r));
  wire fa_s_r, fa_c_r;   full_adder_using_nor  u_far(.a(a), .b(b), .cin(cin), .sum(fa_s_r), .cout(fa_c_r));
  integer i;
  task chk(input val, input exp, input [127:0] nm);
    if (val !== exp) begin errs=errs+1; $display("  MISMATCH %0s a=%b b=%b cin=%b got=%b exp=%b", nm, a, b, cin, val, exp); end
  endtask
  initial begin
    for (i=0;i<8;i=i+1) begin
      {a,b,cin} = i[2:0]; #1;
      chk(y_not_nand, ~a,      "not_nand");
      chk(y_and_nand, a&b,     "and_nand");
      chk(y_or_nand,  a|b,     "or_nand");
      chk(y_xor_nand, a^b,     "xor_nand");
      chk(ha_s_n, a^b,         "ha_nand.sum");
      chk(ha_c_n, a&b,         "ha_nand.carry");
      chk(fa_s_n, a^b^cin,     "fa_nand.sum");
      chk(fa_c_n, (a&b)|(cin&(a^b)), "fa_nand.cout");
      chk(y_not_nor, ~a,       "not_nor");
      chk(y_and_nor, a&b,      "and_nor");
      chk(y_or_nor,  a|b,      "or_nor");
      chk(y_xor_nor, a^b,      "xor_nor");
      chk(ha_s_r, a^b,         "ha_nor.sum");
      chk(ha_c_r, a&b,         "ha_nor.carry");
      chk(fa_s_r, a^b^cin,     "fa_nor.sum");
      chk(fa_c_r, (a&b)|(cin&(a^b)), "fa_nor.cout");
    end
    if (errs==0) $display("universal-gate cells exhaustive: 0 errors");
    else         $display("universal-gate cells: %0d ERRORS", errs);
  end
endmodule
