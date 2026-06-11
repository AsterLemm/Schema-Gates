// Golden test: gpu_frame_crc32. Same frame twice -> same signature; one
// changed pixel -> different; swapped pixel ORDER -> different; frame
// index counts latches; accept=0 pixels are ignored.
module tb;
    integer errs = 0;
    reg clk = 0, rst = 1;
    reg pv = 0, acc = 1, fs = 0, fd = 0;
    reg [7:0] x = 0, y = 0; reg [23:0] rgb = 0;
    wire [31:0] sig; wire sv; wire [15:0] fidx;
    gpu_frame_crc32 u(.clk(clk), .reset(rst), .px_valid(pv), .accept(acc),
        .px_x(x), .px_y(y), .px_rgb(rgb), .frame_start(fs), .frame_done(fd),
        .frame_sig(sig), .sig_valid(sv), .frame_index(fidx));
    always #5 clk = ~clk;

    task px; input [7:0] xi, yi; input [23:0] c; begin
        @(posedge clk); pv <= 1; x <= xi; y <= yi; rgb <= c;
        @(posedge clk); pv <= 0;
    end endtask
    task fstart; begin @(posedge clk); fs <= 1; @(posedge clk); fs <= 0; end endtask
    task fdone;  begin @(posedge clk); fd <= 1; @(posedge clk); fd <= 0;
                       @(posedge clk); end endtask

    reg [31:0] sA, sB, sC, sD;
    initial begin
        repeat (3) @(posedge clk); rst = 0;
        fstart; px(1,2,24'h111111); px(3,4,24'h222222); fdone; sA = sig;
        fstart; px(1,2,24'h111111); px(3,4,24'h222222); fdone; sB = sig;
        fstart; px(1,2,24'h111111); px(3,4,24'h222223); fdone; sC = sig;
        fstart; px(3,4,24'h222222); px(1,2,24'h111111); fdone; sD = sig;
        if (sA !== sB)      errs = errs + 1;   // deterministic
        if (sA === sC)      errs = errs + 1;   // value-sensitive
        if (sA === sD)      errs = errs + 1;   // order-sensitive
        if (fidx !== 16'd4) errs = errs + 1;
        // accept gating: a frame whose pixels are all masked == empty frame
        fstart; fdone; sA = sig;               // truly empty
        fstart; acc = 0; px(1,2,24'h111111); acc = 1; fdone;
        if (sig !== sA)     errs = errs + 1;
        $display("gpu_frame_crc32 signature: %0d errors", errs);
        $finish;
    end
endmodule
