// Golden test: gpu_vector32. One primitive of each type (hline, vline,
// rect, point) with the point overlapping the rect to prove painter
// priority, checked against the RGB12 -> RGB24 nibble expansion.
module tb;
    integer errs = 0;
    reg clk = 0, rst = 1;
    reg we = 0; reg [3:0] ad; reg [31:0] wd;
    wire pv; wire [4:0] px, py; wire [23:0] pr;
    gpu_vector32 u(.clk(clk), .reset(rst), .gpu_we(we), .gpu_addr(ad),
        .gpu_wdata(wd), .gpu_rdata(), .screen_ready(1'b1),
        .frame_start(), .frame_done(), .enable(), .fill(),
        .px_valid(pv), .px_x(px), .px_y(py), .px_rgb(pr));
    always #5 clk = ~clk;

    task w; input [3:0] a; input [31:0] d;
        begin @(posedge clk); we<=1; ad<=a; wd<=d; @(posedge clk); we<=0; end
    endtask
    reg [23:0] fb [0:1023];
    always @(posedge clk) if (pv) fb[{py, px}] <= pr;

    initial begin
        repeat (4) @(posedge clk); rst = 0; repeat (2) @(posedge clk);
        w(4'd1, 32'h9);
        w(4'd4, 32'd1); w(4'd5, 32'h11); w(4'd6, 32'hF00);   // hline, red
        w(4'd7, ( 2<<10) |  3); w(4'd7, ( 2<<10) |  9);
        w(4'd4, 32'd2); w(4'd5, 32'h12); w(4'd6, 32'h0F0);   // vline, green
        w(4'd7, ( 5<<10) | 20); w(4'd7, (30<<10) | 20);
        w(4'd4, 32'd5); w(4'd5, 32'h13); w(4'd6, 32'h00F);   // rect, blue
        w(4'd7, ( 8<<10) |  8); w(4'd7, (12<<10) | 12);
        w(4'd4, 32'd6); w(4'd5, 32'h10); w(4'd6, 32'hFFF);   // point, white
        w(4'd7, ( 9<<10) |  9);
        w(4'd1, 32'h19);
        repeat (4000) @(posedge clk);
        if (fb[{5'd2, 5'd3}]  !== 24'hFF0000) errs = errs + 1;  // hline start
        if (fb[{5'd2, 5'd9}]  !== 24'hFF0000) errs = errs + 1;  // hline end (incl)
        if (fb[{5'd2, 5'd10}] !== 24'h000000) errs = errs + 1;  // past the end
        if (fb[{5'd5, 5'd20}] !== 24'h00FF00) errs = errs + 1;  // vline top
        if (fb[{5'd30,5'd20}] !== 24'h00FF00) errs = errs + 1;  // vline bottom
        if (fb[{5'd9, 5'd9}]  !== 24'hFFFFFF) errs = errs + 1;  // point over rect
        if (fb[{5'd8, 5'd8}]  !== 24'h0000FF) errs = errs + 1;  // rect corner
        if (fb[{5'd12,5'd12}] !== 24'h0000FF) errs = errs + 1;  // rect far corner
        if (fb[{5'd13,5'd12}] !== 24'h000000) errs = errs + 1;  // outside rect
        $display("gpu_vector32 primitive suite: %0d errors", errs);
        $finish;
    end
endmodule
