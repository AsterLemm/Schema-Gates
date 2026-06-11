// ============================================================================
// tb_game_tetris.v -- self-checking testbench for game_tetris
// ----------------------------------------------------------------------------
// Run:  iverilog -g2001 -o tb src/games/game_tetris.v \
//                          tests/games/tb_game_tetris.v  &&  vvp tb
// Prints one final PASS/FAIL line.  Simulation only -- not synthesizable.
//
// Covers: the first spawn after reset (piece count 1, a valid next-piece
// preview), a hard-drop-only run that towers pieces up the spawn column
// until top-out (game over within 300 drops, at least 5 pieces placed,
// and -- because nothing is steered sideways -- the line counter must stay
// at 0 the whole way), and btn_new restarting cleanly.
// ============================================================================
`timescale 1ns/1ns

module tb_game_tetris;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg en  = 1'b1;
  reg btn_left = 1'b0, btn_right = 1'b0, btn_rot = 1'b0;
  reg btn_down = 1'b0, btn_drop = 1'b0, btn_new = 1'b0;
  reg [1:0] speed = 2'd0;          // slowest gravity; drops do the work

  wire [3:0] px_x;
  wire [4:0] px_y;
  wire       px_en, px_clear, px_fill, frame;
  wire [7:0] o_lines, o_pieces;
  wire [2:0] o_next;
  wire       o_over;

  game_tetris dut (
    .clk(clk), .rst(rst), .en(en),
    .btn_left(btn_left), .btn_right(btn_right), .btn_rot(btn_rot),
    .btn_down(btn_down), .btn_drop(btn_drop), .btn_new(btn_new),
    .speed(speed),
    .px_x(px_x), .px_y(px_y), .px_en(px_en), .px_clear(px_clear),
    .px_fill(px_fill), .frame(frame),
    .o_lines(o_lines), .o_pieces(o_pieces), .o_next(o_next), .o_over(o_over)
  );

  always #5 clk = ~clk;

  integer errors = 0;

  task chk;
    input cond;
    input [47*8:1] msg;
    begin
      if (!cond) begin
        errors = errors + 1;
        $display("FAIL: %0s  (t=%0t)", msg, $time);
      end
    end
  endtask

  task wait_frame;
    begin
      @(posedge clk);
      while (frame !== 1'b1) @(posedge clk);
    end
  endtask

  task wait_frames;
    input integer n;
    integer k;
    begin
      for (k = 0; k < n; k = k + 1) wait_frame;
    end
  endtask

  task press_drop; begin btn_drop = 1; repeat (4) @(posedge clk); btn_drop = 0; repeat (4) @(posedge clk); end endtask
  task press_new;  begin btn_new  = 1; repeat (4) @(posedge clk); btn_new  = 0; repeat (4) @(posedge clk); end endtask

  integer drops;

  // invariants, every clock
  always @(posedge clk) begin
    if (!rst && en) begin
      if (px_en && px_clear)   begin errors = errors + 1; $display("FAIL: px_en during px_clear (t=%0t)", $time); end
      if (px_clear && px_fill) begin errors = errors + 1; $display("FAIL: px_clear and px_fill together (t=%0t)", $time); end
      if (px_x > 4'd11 || px_y > 5'd21)
                               begin errors = errors + 1; $display("FAIL: raster out of 12x22 (t=%0t)", $time); end
      if (o_next > 3'd6)       begin errors = errors + 1; $display("FAIL: next piece out of 0..6 (t=%0t)", $time); end
      if (o_lines != 8'd0)     begin errors = errors + 1; $display("FAIL: a line cleared with no steering (t=%0t)", $time); end
    end
  end

  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    wait_frames(3);

    chk(o_pieces == 8'd1, "piece count not 1 after first spawn");
    chk(!o_over, "over straight out of reset");
    chk(o_lines == 8'd0, "lines nonzero after reset");

    // hard-drop the spawn column into a tower until the well tops out
    drops = 0;
    while (!o_over && (drops < 300)) begin
      press_drop;
      wait_frames(2);
      drops = drops + 1;
    end
    chk(o_over, "no top-out within 300 hard drops");
    chk(o_pieces >= 8'd5, "topped out in under 5 pieces");

    // drops are dead after game over
    press_drop;
    wait_frames(2);
    chk(o_over, "o_over dropped after a dead-state press");

    // restart: clean field, fresh first piece
    press_new;
    wait_frames(3);
    chk(!o_over, "o_over survives btn_new");
    chk(o_pieces == 8'd1, "piece count not 1 after btn_new");
    chk(o_lines == 8'd0, "lines survive btn_new");

    if (errors == 0) $display("PASS: tb_game_tetris (0 errors)");
    else             $display("FAIL: tb_game_tetris (%0d errors)", errors);
    $finish;
  end

  initial begin
    #10_000_000;
    $display("FAIL: tb_game_tetris global timeout");
    $finish;
  end

endmodule
