// ============================================================================
// tb_game_snake.v -- self-checking testbench for game_snake
// ----------------------------------------------------------------------------
// Run:  iverilog -g2001 -o tb src/games/game_snake.v \
//                          tests/games/tb_game_snake.v  &&  vvp tb
// Prints one final PASS/FAIL line.  Simulation only -- not synthesizable.
//
// Covers: reset state (length 3, heading right from (8,8)), the
// 180-degree-reversal guard (pressing left at launch must NOT cause the
// instant self-collision that an honoured reversal would), death at the
// right wall with no input, btn_new restart, and the pixel-bus contract.
// ============================================================================
`timescale 1ns/1ns

module tb_game_snake;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg en  = 1'b1;
  reg btn_up = 1'b0, btn_down = 1'b0, btn_left = 1'b0, btn_right = 1'b0;
  reg btn_new = 1'b0;
  reg [1:0] speed = 2'd3;          // fastest: one move per frame

  wire [3:0] px_x, px_y;
  wire       px_en, px_clear, px_fill, frame;
  wire [6:0] o_len;
  wire       o_over, o_win;

  game_snake dut (
    .clk(clk), .rst(rst), .en(en),
    .btn_up(btn_up), .btn_down(btn_down), .btn_left(btn_left),
    .btn_right(btn_right), .btn_new(btn_new), .speed(speed),
    .px_x(px_x), .px_y(px_y), .px_en(px_en), .px_clear(px_clear),
    .px_fill(px_fill), .frame(frame),
    .o_len(o_len), .o_over(o_over), .o_win(o_win)
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

  task press_left; begin btn_left = 1; repeat (4) @(posedge clk); btn_left = 0; repeat (4) @(posedge clk); end endtask
  task press_new;  begin btn_new  = 1; repeat (4) @(posedge clk); btn_new  = 0; repeat (4) @(posedge clk); end endtask

  // wait until o_over or maxf frames have passed
  task wait_over;
    input integer maxf;
    integer k;
    begin
      k = 0;
      while (!o_over && (k < maxf)) begin
        wait_frame;
        k = k + 1;
      end
    end
  endtask

  // invariants, every clock
  always @(posedge clk) begin
    if (!rst && en) begin
      if (px_en && px_clear)   begin errors = errors + 1; $display("FAIL: px_en during px_clear (t=%0t)", $time); end
      if (px_clear && px_fill) begin errors = errors + 1; $display("FAIL: px_clear and px_fill together (t=%0t)", $time); end
      if (o_len < 7'd3)        begin errors = errors + 1; $display("FAIL: length below 3 (t=%0t)", $time); end
    end
  end

  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    wait_frames(2);

    chk(o_len == 7'd3, "length not 3 after reset");
    chk(!o_over && !o_win, "over/win set after reset");

    // reversal guard: heading right, an immediate LEFT press must be
    // ignored.  If it were honoured, the head would step onto body[1]
    // and the game would be over within a tick or two.
    press_left;
    wait_frames(3);
    chk(!o_over, "honoured 180-degree reversal (self-collision)");

    // with no further input the snake runs into the right wall
    wait_over(32);
    chk(o_over, "no wall death within 32 frames");
    chk(!o_win, "win flagged on a crash");

    // restart
    press_new;
    wait_frames(2);
    chk(!o_over, "o_over survives btn_new");
    chk(o_len == 7'd3, "length not 3 after btn_new");

    // and it dies again on its own (fresh run is live, not frozen)
    wait_over(32);
    chk(o_over, "second run never ended");

    if (errors == 0) $display("PASS: tb_game_snake (0 errors)");
    else             $display("FAIL: tb_game_snake (%0d errors)", errors);
    $finish;
  end

  initial begin
    #2_000_000;
    $display("FAIL: tb_game_snake global timeout");
    $finish;
  end

endmodule
