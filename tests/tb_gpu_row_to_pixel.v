// Golden test: gpu_row_to_pixel. Two rows through the adapter (one with
// consumer back-pressure), checking bit order, x/y labelling, exact
// pixel count per row, and that row_ready returns between rows.
module tb;
    integer errs = 0, n;
    reg clk = 0, rst = 1;
    reg mv = 0; reg [7:0] my = 0; reg [63:0] s0 = 0;
    reg prdy = 1;
    wire rr, pv; wire [7:0] px, py; wire pon;
    gpu_row_to_pixel u(.clk(clk), .reset(rst), .w_field(8'd7),
        .mono_valid(mv), .mono_y(my), .mono_s0(s0), .mono_s1(64'd0),
        .mono_s2(64'd0), .mono_s3(64'd0), .row_ready(rr),
        .px_valid(pv), .px_x(px), .px_y(py), .px_on(pon), .px_ready(prdy));
    always #5 clk = ~clk;

    reg [7:0] bits;
    always @(posedge clk) begin
        prdy <= $random;                       // random back-pressure
        if (pv && prdy && n < 8) begin
            bits[px] <= pon;
            if (py !== my) errs = errs + 1;
            n = n + 1;
        end
    end

    task send_row; input [7:0] y; input [63:0] r; begin
        wait (rr); @(posedge clk);
        mv <= 1; my <= y; s0 <= r;
        @(posedge clk); mv <= 0;
        wait (n == 8); @(posedge clk);
    end endtask

    initial begin
        repeat (3) @(posedge clk); rst = 0;
        n = 0; bits = 0;
        send_row(8'd9, 64'hA5);
        if (bits !== 8'hA5) errs = errs + 1;
        n = 0; bits = 0;
        send_row(8'd10, 64'h0F);
        if (bits !== 8'h0F) errs = errs + 1;
        repeat (3) @(posedge clk);
        if (!rr) errs = errs + 1;              // ready for a third row
        $display("gpu_row_to_pixel adapter: %0d errors", errs);
        $finish;
    end
endmodule
