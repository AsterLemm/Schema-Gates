// Golden test: gpu_raster64. One triangle (10,5)-(50,5)-(30,40) committed
// through the bus; checks pixel count against the analytic area, vertex
// inclusivity (edge pixels count), interior/exterior spot points, and
// that a clockwise winding of the same triangle renders identically.
module tb;
    integer errs = 0, i, j, cnt, cnt2;
    reg clk = 0, rst = 1;
    reg we = 0; reg [3:0] ad; reg [31:0] wd;
    wire mv; wire [5:0] my; wire [63:0] mr;
    gpu_raster64 u(.clk(clk), .reset(rst), .gpu_we(we), .gpu_addr(ad), .gpu_wdata(wd),
        .gpu_rdata(), .screen_ready(1'b1), .frame_start(), .frame_done(),
        .enable(), .fill(), .mono_valid(mv), .mono_y(my), .mono_s0(mr));
    always #5 clk = ~clk;

    task w; input [3:0] a; input [31:0] d;
        begin @(posedge clk); we<=1; ad<=a; wd<=d; @(posedge clk); we<=0; end
    endtask
    reg [63:0] rows [0:63];
    always @(posedge clk) if (mv) rows[my] <= mr;

    initial begin
        repeat (4) @(posedge clk); rst = 0; repeat (2) @(posedge clk);
        // counter-clockwise winding
        w(4'd1, 32'h9);                     // wait | enable
        w(4'd4, 32'd0);                     // slot 0, vert 0
        w(4'd5, 32'h10);                    // en
        w(4'd7, ( 5<<10) | 10);
        w(4'd7, ( 5<<10) | 50);
        w(4'd7, (40<<10) | 30);
        w(4'd1, 32'h19);                    // commit
        repeat (5000) @(posedge clk);
        cnt = 0; for (i=0;i<64;i=i+1) for (j=0;j<64;j=j+1) cnt = cnt + rows[i][j];
        // area = |(50-10)*(40-5)|/2 = 700; inclusive edges add the perimeter
        if (!(cnt > 650 && cnt < 800)) errs = errs + 1;
        if (rows[20][30] !== 1'b1) errs = errs + 1;   // interior
        if (rows[ 5][10] !== 1'b1) errs = errs + 1;   // vertex (on edges)
        if (rows[ 5][50] !== 1'b1) errs = errs + 1;
        if (rows[40][30] !== 1'b1) errs = errs + 1;
        if (rows[ 0][ 0] !== 1'b0) errs = errs + 1;   // exterior
        if (rows[ 4][30] !== 1'b0) errs = errs + 1;   // just above apex row
        if (rows[41][30] !== 1'b0) errs = errs + 1;   // just below tip
        // same triangle, clockwise winding: sign test must accept it
        w(4'd4, 32'd0);
        w(4'd7, ( 5<<10) | 10);
        w(4'd7, (40<<10) | 30);
        w(4'd7, ( 5<<10) | 50);
        w(4'd1, 32'h19);
        repeat (5000) @(posedge clk);
        cnt2 = 0; for (i=0;i<64;i=i+1) for (j=0;j<64;j=j+1) cnt2 = cnt2 + rows[i][j];
        if (cnt2 !== cnt) errs = errs + 1;
        $display("gpu_raster64 triangle rasterisation: %0d errors", errs);
        $finish;
    end
endmodule
