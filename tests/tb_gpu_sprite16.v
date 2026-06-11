// Golden test: gpu_sprite16. Loads a checkerboard stamp into one sprite
// slot via the auto-incrementing STAMPROW port, places it at (3,2) with
// colour 5, and checks the pixel-serial scanout reproduces the pattern
// at the right offset (including transparent holes and the row above).
module tb;
    integer errs = 0, i;
    reg clk = 0, rst = 1;
    reg we = 0; reg [3:0] ad; reg [31:0] wd;
    wire pv; wire [3:0] px, py, pm;
    gpu_sprite16 u(.clk(clk), .reset(rst), .gpu_we(we), .gpu_addr(ad),
        .gpu_wdata(wd), .gpu_rdata(), .screen_ready(1'b1),
        .frame_start(), .frame_done(), .enable(), .fill(),
        .px_valid(pv), .px_x(px), .px_y(py), .px_mux(pm));
    always #5 clk = ~clk;

    task w; input [3:0] a; input [31:0] d;
        begin @(posedge clk); we<=1; ad<=a; wd<=d; @(posedge clk); we<=0; end
    endtask
    reg [3:0] fb [0:255];
    always @(posedge clk) if (pv) fb[{py, px}] <= pm;

    initial begin
        repeat (4) @(posedge clk); rst = 0; repeat (2) @(posedge clk);
        w(4'd1, 32'h9);                          // wait | enable
        w(4'd4, 32'h02);                         // slot 2, row_ptr 0
        w(4'd5, 32'h10);                         // en
        w(4'd6, 32'd5);                          // colour 5
        w(4'd7, (2<<10) | 3);                    // position (3,2)
        for (i = 0; i < 8; i = i + 1)            // checker: 55/AA rows
            w(4'd9, (i & 1) ? 32'hAA : 32'h55);
        w(4'd1, 32'h19);                         // commit
        repeat (900) @(posedge clk);
        if (fb[{4'd2,4'd3}]  !== 4'd5) errs = errs + 1;  // row0 bit0 set
        if (fb[{4'd2,4'd4}]  !== 4'd0) errs = errs + 1;  // row0 bit1 hole
        if (fb[{4'd3,4'd4}]  !== 4'd5) errs = errs + 1;  // row1 bit1 set
        if (fb[{4'd3,4'd3}]  !== 4'd0) errs = errs + 1;  // row1 bit0 hole
        if (fb[{4'd1,4'd3}]  !== 4'd0) errs = errs + 1;  // above the sprite
        if (fb[{4'd9,4'd10}] !== 4'd5) errs = errs + 1;  // bottom-right corner
        if (fb[{4'd2,4'd11}] !== 4'd0) errs = errs + 1;  // right of the sprite
        $display("gpu_sprite16 stamp scanout: %0d errors", errs);
        $finish;
    end
endmodule
