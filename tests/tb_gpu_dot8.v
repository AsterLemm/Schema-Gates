// Golden test: gpu_dot8. Programs two point slots through the MMIO bus,
// commits, captures the row-serial scanout, and checks exactly the two
// expected pixels light. Also checks a re-commit with one slot disabled.
module tb;
    integer errs = 0, i, j, cnt;
    reg clk = 0, rst = 1;
    reg we = 0; reg [3:0] ad; reg [31:0] wd;
    wire mv; wire [2:0] my; wire [7:0] mr;
    wire fs, fd;
    gpu_dot8 u(.clk(clk), .reset(rst), .gpu_we(we), .gpu_addr(ad), .gpu_wdata(wd),
        .gpu_rdata(), .screen_ready(1'b1), .frame_start(fs), .frame_done(fd),
        .enable(), .fill(), .mono_valid(mv), .mono_y(my), .mono_row(mr));
    always #5 clk = ~clk;

    task w; input [3:0] a; input [31:0] d;
        begin @(posedge clk); we<=1; ad<=a; wd<=d; @(posedge clk); we<=0; end
    endtask
    reg [7:0] rows [0:7];
    always @(posedge clk) if (mv) rows[my] <= mr;

    initial begin
        repeat (4) @(posedge clk); rst = 0; repeat (2) @(posedge clk);
        // frame 1: points (1,1) and (6,3)
        w(4'd1, 32'h9);              // CONTROL: wait_for_screen | enable
        w(4'd4, 32'd0);              // SEL slot 0
        w(4'd5, 32'h10);             // PRIMHDR en
        w(4'd7, (1<<10) | 1);        // VERT y=1 x=1
        w(4'd4, 32'd1);              // SEL slot 1
        w(4'd5, 32'h10);
        w(4'd7, (3<<10) | 6);        // VERT y=3 x=6
        w(4'd1, 32'h19);             // commit | wait | enable
        repeat (40) @(posedge clk);
        if (rows[1] !== 8'h02) errs = errs + 1;
        if (rows[3] !== 8'h40) errs = errs + 1;
        cnt = 0; for (i=0;i<8;i=i+1) for (j=0;j<8;j=j+1) cnt = cnt + rows[i][j];
        if (cnt !== 2) errs = errs + 1;
        // frame 2: disable slot 1, move slot 0 -> only (4,6) lights
        w(4'd4, 32'd1); w(4'd5, 32'h00);   // slot 1 off
        w(4'd4, 32'd0); w(4'd7, (6<<10) | 4);
        w(4'd1, 32'h19);
        repeat (40) @(posedge clk);
        cnt = 0; for (i=0;i<8;i=i+1) for (j=0;j<8;j=j+1) cnt = cnt + rows[i][j];
        if (cnt !== 1)            errs = errs + 1;
        if (rows[6] !== 8'h10)    errs = errs + 1;
        $display("gpu_dot8 point scanout: %0d errors", errs);
        $finish;
    end
endmodule
