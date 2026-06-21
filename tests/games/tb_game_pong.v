// ============================================================================
// tb_game_pong.v -- self-checking testbench for game_pong
// ----------------------------------------------------------------------------
// Run:  iverilog -g2001 -o tb src/games/game_pong.v \
//                          tests/games/tb_game_pong.v  &&  vvp tb
// Prints one final PASS/FAIL line.  Simulation only -- not synthesizable.
//
// Covers: reset state (0-0, not over), the en freeze (no frame pulses, no
// score changes while en is low), and the deterministic CPU rout: with P1
// static and cpu_p2 high, every serve reaches the receiving column at row
// 40 or row 6 -- outside P1's fixed 20..27 paddle band but always within
// the tracking CPU's reach -- so P2 wins 7-0 (~455 frames; the previous
// simulated session measured exactly that).  btn_new is then pressed and
// the second game must end 7-0 the same way.  Always-block invariants:
// px_clear/px_fill exclusivity, px_en never on a clear cycle, frame only
// on the clear cycle, px_y inside the 48-row screen, and score
// monotonicity outside a short window around btn_new.
// ============================================================================
`timescale 1ns/1ns

module tb_game_pong;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg en  = 1'b1;
  reg btn_p1_up = 1'b0, btn_p1_dn = 1'b0;
  reg btn_p2_up = 1'b0, btn_p2_dn = 1'b0;
  reg cpu_p2 = 1'b1;               // machine plays the right paddle
  reg btn_new = 1'b0;

  wire [5:0] px_x, px_y;
  wire       px_en, px_clear, px_fill, frame;
  wire [2:0] o_s1, o_s2;
  wire       o_over, o_winner;

  game_pong dut (
    .clk(clk), .rst(rst), .en(en),
    .btn_p1_up(btn_p1_up), .btn_p1_dn(btn_p1_dn),
    .btn_p2_up(btn_p2_up), .btn_p2_dn(btn_p2_dn),
    .cpu_p2(cpu_p2), .btn_new(btn_new),
    .px_x(px_x), .px_y(px_y), .px_en(px_en), .px_clear(px_clear),
    .px_fill(px_fill), .frame(frame),
    .o_s1(o_s1), .o_s2(o_s2), .o_over(o_over), .o_winner(o_winner)
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

  task press_new; begin btn_new = 1; repeat (4) @(posedge clk); btn_new = 0; repeat (8) @(posedge clk); end endtask

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

  // frame pulses seen so far (for the en-freeze check)
  integer fcount = 0;
  always @(posedge clk) if (frame === 1'b1) fcount = fcount + 1;

  // scores may only drop in a short window around btn_new: the pulse from
  // the 2-flop synchroniser clears them ~3 clocks after the button rises,
  // so btn_new high plus 12 clocks of grace after release covers it.
  reg [3:0] clr_cnt = 4'd0;
  wire      clr_ok  = btn_new || (clr_cnt != 4'd0);
  always @(posedge clk) begin
    if (btn_new)              clr_cnt <= 4'd12;
    else if (clr_cnt != 4'd0) clr_cnt <= clr_cnt - 4'd1;
  end

  // invariants, every clock
  reg [2:0] s1_p = 3'd0, s2_p = 3'd0;
  always @(posedge clk) begin
    if (!rst && en) begin
      if (px_en && (px_clear || px_fill))
        begin errors = errors + 1; $display("FAIL: px_en on a clear/fill cycle (t=%0t)", $time); end
      if (px_clear && px_fill)
        begin errors = errors + 1; $display("FAIL: px_clear and px_fill together (t=%0t)", $time); end
      if (frame !== (px_clear | px_fill))
        begin errors = errors + 1; $display("FAIL: frame not the clear/fill cycle (t=%0t)", $time); end
      if (px_y > 6'd47)
        begin errors = errors + 1; $display("FAIL: px_y above row 47 (t=%0t)", $time); end
      if (!clr_ok && ((o_s1 < s1_p) || (o_s2 < s2_p)))
        begin errors = errors + 1; $display("FAIL: score dropped outside btn_new (t=%0t)", $time); end
    end
    s1_p <= o_s1;
    s2_p <= o_s2;
  end

  integer f_mark;

  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    wait_frames(2);

    // reset state
    chk(o_s1 == 3'd0 && o_s2 == 3'd0, "scores not 0-0 after reset");
    chk(!o_over,                      "o_over set after reset");

    // en freeze: no frames, no score movement
    en = 1'b0;
    f_mark = fcount;
    repeat (10000) @(posedge clk);   // > 3 frame periods
    chk(fcount == f_mark,             "frame pulsed while en was low");
    chk(o_s1 == 3'd0 && o_s2 == 3'd0, "score moved while en was low");
    en = 1'b1;

    // game 1: static P1 vs the CPU.  Every serve reaches the receiving
    // column out of P1's band, so P2 runs the table.
    wait_over(1200);
    chk(o_over,         "game 1 not over within 1200 frames");
    chk(o_winner,       "game 1 winner is not P2");
    chk(o_s2 == 3'd7,   "game 1 P2 score is not 7");
    chk(o_s1 == 3'd0,   "game 1 P1 scored against the CPU");

    // restart: scores clear, game live again
    press_new;
    chk(o_s1 == 3'd0 && o_s2 == 3'd0, "scores survive btn_new");
    chk(!o_over,                      "o_over survives btn_new");

    // game 2 must play out the same 7-0 way
    wait_over(1200);
    chk(o_over,         "game 2 not over within 1200 frames");
    chk(o_winner,       "game 2 winner is not P2");
    chk(o_s2 == 3'd7,   "game 2 P2 score is not 7");
    chk(o_s1 == 3'd0,   "game 2 P1 scored against the CPU");

    if (errors == 0) $display("PASS: tb_game_pong (0 errors)");
    else             $display("FAIL: tb_game_pong (%0d errors)", errors);
    $finish;
  end

  initial begin
    #80_000_000;
    $display("FAIL: tb_game_pong global timeout");
    $finish;
  end

endmodule
