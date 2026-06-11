// Golden test: gpu_mmio_arbiter2 truth table -- A only, B only, both
// (A wins, b_dropped flags the loss), neither.
module tb;
    integer errs = 0;
    reg awe, bwe; reg [3:0] aa, ba; reg [31:0] aw, bw;
    wire gwe; wire [3:0] ga; wire [31:0] gw; wire bdrop, gb;
    gpu_mmio_arbiter2 u(.a_we(awe), .a_addr(aa), .a_wdata(aw),
        .b_we(bwe), .b_addr(ba), .b_wdata(bw),
        .gpu_we(gwe), .gpu_addr(ga), .gpu_wdata(gw),
        .b_dropped(bdrop), .grant_b(gb));
    initial begin
        aa = 4'd2; aw = 32'hAAAA; ba = 4'd7; bw = 32'hBBBB;
        awe = 1; bwe = 0; #1;
        if (!(gwe && ga === 4'd2 && gw === 32'hAAAA && !gb && !bdrop)) errs = errs + 1;
        awe = 0; bwe = 1; #1;
        if (!(gwe && ga === 4'd7 && gw === 32'hBBBB && gb && !bdrop))  errs = errs + 1;
        awe = 1; bwe = 1; #1;
        if (!(gwe && ga === 4'd2 && gw === 32'hAAAA && !gb && bdrop))  errs = errs + 1;
        awe = 0; bwe = 0; #1;
        if (gwe || bdrop || gb) errs = errs + 1;
        $display("gpu_mmio_arbiter2 priority: %0d errors", errs);
        $finish;
    end
endmodule
