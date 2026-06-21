// Golden test: gpu_frame_pacer. Pulse spacing at rate=3 (exactly one
// screen_ready per 4 clocks), free flow at rate=0, frame counting, and
// the in_frame window between frame_start and frame_done.
module tb;
    integer errs = 0, pulses, k;
    reg clk = 0, rst = 1;
    reg [15:0] rate; reg fs = 0, fd = 0;
    wire sr; wire [15:0] fc; wire ft, inf;
    gpu_frame_pacer u(.clk(clk), .reset(rst), .rate(rate),
        .frame_start(fs), .frame_done(fd), .screen_ready(sr),
        .frame_count(fc), .frame_tick(ft), .in_frame(inf));
    always #5 clk = ~clk;
    initial begin
        rate = 16'd3;
        repeat (3) @(posedge clk); rst = 0; @(posedge clk);
        pulses = 0;
        for (k = 0; k < 40; k = k + 1) begin
            @(posedge clk); if (sr) pulses = pulses + 1;
        end
        if (pulses !== 10) errs = errs + 1;          // every 4th clock
        rate = 16'd0;                                 // free flow
        repeat (2) @(posedge clk);
        pulses = 0;
        for (k = 0; k < 10; k = k + 1) begin
            @(posedge clk); if (sr) pulses = pulses + 1;
        end
        if (pulses !== 10) errs = errs + 1;          // held high
        @(posedge clk); fs <= 1; @(posedge clk); fs <= 0; @(posedge clk);
        if (!inf)          errs = errs + 1;
        @(posedge clk); fd <= 1; @(posedge clk); fd <= 0; @(posedge clk);
        if (fc !== 16'd1)  errs = errs + 1;
        if (inf)           errs = errs + 1;
        $display("gpu_frame_pacer heartbeat: %0d errors", errs);
        $finish;
    end
endmodule
