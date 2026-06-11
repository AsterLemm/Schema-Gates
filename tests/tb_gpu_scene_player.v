// FT_ALSO: GPUs/GPU.v GPUs/gpu_frame_pacer.v GPUs/gpu_frame_crc32.v
// Golden test: the CPU-less demo rig. gpu_scene_player programs the
// FLAGSHIP GPU with a 3D triangle and re-rotates it each frame_done;
// gpu_frame_pacer paces the scan; gpu_frame_crc32 signs each frame.
// Checks: every pixel of every frame accepted exactly once, the scene
// renders (lit pixels), rotation changes the signature each frame, and
// with step=0 consecutive signatures are identical (bit-deterministic).
module tb;
    integer errs = 0, npx = 0, nlit = 0, nsig = 0;
    reg clk = 0, rst = 1;
    reg [7:0] step;
    wire we; wire [3:0] ad; wire [31:0] wd;
    wire fs, fd, sr;
    wire pxv; wire [4:0] pxx, pxy; wire [23:0] pxr;
    wire [31:0] sig; wire sv;

    gpu_scene_player play(.clk(clk), .reset(rst), .gpu_we(we), .gpu_addr(ad),
        .gpu_wdata(wd), .frame_done(fd), .step(step), .angle(), .playing());
    gpu_frame_pacer pace(.clk(clk), .reset(rst), .rate(16'd1),
        .frame_start(fs), .frame_done(fd), .screen_ready(sr),
        .frame_count(), .frame_tick(), .in_frame());
    GPU gpu(.clk(clk), .reset(rst), .gpu_we(we), .gpu_addr(ad), .gpu_wdata(wd),
        .gpu_rdata(), .screen_ready(sr), .frame_start(fs), .frame_done(fd),
        .scr_w(), .scr_h(), .scr_ctype(), .enable(), .fill(),
        .mono_valid(), .mono_y(), .mono_s0(), .mono_s1(), .mono_s2(), .mono_s3(),
        .px_valid(pxv), .px_x(pxx), .px_y(pxy), .px_mux(), .px_rgb(pxr));
    gpu_frame_crc32 crc(.clk(clk), .reset(rst), .px_valid(pxv), .accept(sr),
        .px_x({3'd0, pxx}), .px_y({3'd0, pxy}), .px_rgb(pxr),
        .frame_start(fs), .frame_done(fd),
        .frame_sig(sig), .sig_valid(sv), .frame_index());
    always #5 clk = ~clk;

    reg [31:0] sigs [0:3];
    always @(posedge clk) begin
        if (pxv && sr) begin
            npx = npx + 1;
            if (pxr != 24'd0) nlit = nlit + 1;
        end
        if (sv && nsig < 4) begin sigs[nsig] = sig; nsig = nsig + 1; end
    end

    initial begin
        step = 8'd7;
        repeat (4) @(posedge clk); rst = 0;
        wait (nsig == 3);
        if (npx  !== 3*1024)     errs = errs + 1;   // no skipped pixels
        if (nlit  <  100)        errs = errs + 1;   // triangle rendered
        if (sigs[0] === sigs[1]) errs = errs + 1;   // rotation visible
        if (sigs[1] === sigs[2]) errs = errs + 1;
        // step=0: the very same scene every frame -> identical signatures
        rst = 1; step = 8'd0; nsig = 0;
        repeat (4) @(posedge clk); rst = 0;
        wait (nsig == 2);
        if (sigs[0] !== sigs[1]) errs = errs + 1;
        $display("gpu_scene_player standalone rig: %0d errors", errs);
        $finish;
    end
endmodule
