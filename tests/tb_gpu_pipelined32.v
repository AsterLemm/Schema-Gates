// Golden test: gpu_pipelined32. A rect + an overlapping higher-priority
// point, scanned out through the 3-stage pixel pipeline while the
// consumer applies RANDOM back-pressure on screen_ready. Checks that
// exactly 1024 pixels arrive, strictly in scan order, with correct
// colours -- i.e. the stall logic never drops or duplicates a pixel.
// Also checks the ppln_* synchronizer strobes: with ppln_rect held low
// the rect class is operand-isolated away and contributes nothing.
module tb;
    integer errs = 0, ncap, i;
    reg clk = 0, rst = 1;
    reg we = 0; reg [3:0] ad; reg [31:0] wd;
    reg sready = 0, prect = 1;
    wire pv; wire [4:0] px, py; wire [23:0] prgb;
    gpu_pipelined32 u(.clk(clk), .reset(rst), .gpu_we(we), .gpu_addr(ad),
        .gpu_wdata(wd), .gpu_rdata(),
        .ppln_point(1'b1), .ppln_line(1'b1), .ppln_rect(prect),
        .screen_ready(sready), .frame_start(), .frame_done(),
        .enable(), .fill(),
        .px_valid(pv), .px_x(px), .px_y(py), .px_rgb(prgb));
    always #5 clk = ~clk;

    task w; input [3:0] a; input [31:0] d;
        begin @(posedge clk); we<=1; ad<=a; wd<=d; @(posedge clk); we<=0; end
    endtask

    reg [23:0] fb [0:1023];
    reg order_ok;
    always @(posedge clk) begin
        sready <= $random;                       // random back-pressure
        if (pv && sready) begin                  // valid && ready handshake
            fb[{py, px}] <= prgb;
            if ({py, px} != ncap[9:0]) order_ok = 0;
            ncap = ncap + 1;
        end
    end

    initial begin
        ncap = 0; order_ok = 1;
        repeat (4) @(posedge clk); rst = 0; repeat (2) @(posedge clk);
        // rect slot0 (4,4)-(10,8) colour 111111 ; point slot7 (5,5) colour 222222
        w(4'd1, 32'h9);                          // wait | enable
        w(4'd4, 32'd0); w(4'd5, 32'h13);         // slot0: en, type rect
        w(4'd6, 24'h111111);
        w(4'd7, (4<<10) | 4);  w(4'd7, (8<<10) | 10);
        w(4'd4, 32'd7); w(4'd5, 32'h10);         // slot7: en, type point
        w(4'd6, 24'h222222);
        w(4'd7, (5<<10) | 5);
        w(4'd1, 32'h19);                         // commit
        repeat (6000) @(posedge clk);
        if (ncap !== 1024)                  errs = errs + 1;
        if (!order_ok)                      errs = errs + 1;
        if (fb[{5'd5,5'd5}]   !== 24'h222222) errs = errs + 1;  // point on top
        if (fb[{5'd4,5'd4}]   !== 24'h111111) errs = errs + 1;
        if (fb[{5'd8,5'd10}]  !== 24'h111111) errs = errs + 1;
        if (fb[{5'd8,5'd11}]  !== 24'h000000) errs = errs + 1;
        if (fb[{5'd0,5'd0}]   !== 24'h000000) errs = errs + 1;
        // second frame with ppln_rect low: rect gated off, point survives
        prect = 0; ncap = 0;
        w(4'd1, 32'h19);                         // re-commit same scene
        repeat (6000) @(posedge clk);
        if (ncap !== 1024)                  errs = errs + 1;
        if (fb[{5'd4,5'd4}]   !== 24'h000000) errs = errs + 1;  // rect gone
        if (fb[{5'd5,5'd5}]   !== 24'h222222) errs = errs + 1;  // point alive
        $display("gpu_pipelined32 stall/strobe suite: %0d errors", errs);
        $finish;
    end
endmodule
