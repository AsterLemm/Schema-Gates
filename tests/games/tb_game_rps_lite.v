// ============================================================================
// tb_game_rps_lite.v -- self-checking testbench for game_rps_lite
// ----------------------------------------------------------------------------
// Run:  iverilog -g2001 -o tb src/games/game_rps_lite.v \
//                          tests/games/tb_game_rps_lite.v  &&  vvp tb
// Prints one final PASS/FAIL line.  Simulation only -- not synthesizable.
//
// Covers: all-dark reset state, nine scored rounds (the CPU choice is
// timing-derived, so each round is checked for *consistency*: exactly one
// player lamp, one CPU lamp and one result lamp must light, the result must
// agree with the beats matrix, and exactly the right score must move), the
// rock > paper > scissors chord priority, btn_new darkening the table, and
// the en freeze.  An always-block keeps every lamp group one-hot and in
// lock-step with the others on every clock.
// ============================================================================
`timescale 1ns/1ns

module tb_game_rps_lite;

  localparam [1:0] CH_ROCK = 2'd0, CH_PAPR = 2'd1, CH_SCIS = 2'd2, CH_NONE = 2'd3;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg en  = 1'b1;
  reg btn_rock = 1'b0, btn_paper = 1'b0, btn_scissors = 1'b0, btn_new = 1'b0;

  wire       o_p_rock, o_p_paper, o_p_scissors;
  wire       o_c_rock, o_c_paper, o_c_scissors;
  wire       o_win, o_lose, o_draw;
  wire [3:0] o_score_p, o_score_c;

  game_rps_lite dut (
    .clk(clk), .rst(rst), .en(en),
    .btn_rock(btn_rock), .btn_paper(btn_paper), .btn_scissors(btn_scissors),
    .btn_new(btn_new),
    .o_p_rock(o_p_rock), .o_p_paper(o_p_paper), .o_p_scissors(o_p_scissors),
    .o_c_rock(o_c_rock), .o_c_paper(o_c_paper), .o_c_scissors(o_c_scissors),
    .o_win(o_win), .o_lose(o_lose), .o_draw(o_draw),
    .o_score_p(o_score_p), .o_score_c(o_score_c)
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

  // throw choice 0/1/2 by pressing the matching button
  task throw;
    input [1:0] c;
    begin
      case (c)
        CH_ROCK: btn_rock     = 1;
        CH_PAPR: btn_paper    = 1;
        default: btn_scissors = 1;
      endcase
      repeat (4) @(posedge clk);
      btn_rock = 0; btn_paper = 0; btn_scissors = 0;
      repeat (4) @(posedge clk);
    end
  endtask

  task press_new; begin btn_new = 1; repeat (4) @(posedge clk); btn_new = 0; repeat (4) @(posedge clk); end endtask

  // one-hot lamp trio -> choice code (CH_NONE when all dark)
  function [1:0] lamps;
    input r;
    input p;
    input s;
    begin
      lamps = r ? CH_ROCK : (p ? CH_PAPR : (s ? CH_SCIS : CH_NONE));
    end
  endfunction

  // does choice a beat choice b? (mirror of the DUT's matrix)
  function beats;
    input [1:0] a;
    input [1:0] b;
    begin
      beats = ((a == CH_ROCK) && (b == CH_SCIS)) ||
              ((a == CH_PAPR) && (b == CH_ROCK)) ||
              ((a == CH_SCIS) && (b == CH_PAPR));
    end
  endfunction

  integer r;
  reg [1:0] sel, got_p, got_c;
  reg seen_win, seen_draw, seen_lose;
  reg [3:0] exp_p, exp_c;

  // invariants, every clock: each lamp group is one-hot (or dark), and the
  // three groups light together -- a throw always shows both choices AND a
  // result, idle shows nothing at all
  always @(posedge clk) begin
    if (!rst && en) begin
      if (o_p_rock + o_p_paper + o_p_scissors > 1)
        begin errors = errors + 1; $display("FAIL: player lamps not one-hot (t=%0t)", $time); end
      if (o_c_rock + o_c_paper + o_c_scissors > 1)
        begin errors = errors + 1; $display("FAIL: CPU lamps not one-hot (t=%0t)", $time); end
      if (o_win + o_lose + o_draw > 1)
        begin errors = errors + 1; $display("FAIL: result lamps not one-hot (t=%0t)", $time); end
      if ((o_p_rock | o_p_paper | o_p_scissors) != (o_c_rock | o_c_paper | o_c_scissors))
        begin errors = errors + 1; $display("FAIL: player/CPU lamp groups out of step (t=%0t)", $time); end
      if ((o_p_rock | o_p_paper | o_p_scissors) != (o_win | o_lose | o_draw))
        begin errors = errors + 1; $display("FAIL: choice/result lamp groups out of step (t=%0t)", $time); end
    end
  end

  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    repeat (8) @(posedge clk);

    chk(!o_p_rock && !o_p_paper && !o_p_scissors, "player lamps lit after reset");
    chk(!o_c_rock && !o_c_paper && !o_c_scissors, "CPU lamps lit after reset");
    chk(!o_win && !o_lose && !o_draw,             "result lamps lit after reset");
    chk(o_score_p == 4'd0 && o_score_c == 4'd0,   "scores not 0 after reset");

    // nine rounds, cycling rock -> paper -> scissors three times over.  The
    // CPU pick is the free-running mod-3 counter sampled at the press, so
    // shifting each press by 0/1/2 extra clocks per cycle walks every throw
    // past every possible CPU answer -- a win, a draw and a loss are all
    // guaranteed to happen, and each is checked the moment it does.
    exp_p = 4'd0;
    exp_c = 4'd0;
    seen_win  = 1'b0;
    seen_draw = 1'b0;
    seen_lose = 1'b0;
    for (r = 0; r < 9; r = r + 1) begin
      sel = r % 3;
      repeat (r / 3) @(posedge clk);     // phase-shift the CPU sample
      throw(sel);
      repeat (4) @(posedge clk);
      got_p = lamps(o_p_rock, o_p_paper, o_p_scissors);
      got_c = lamps(o_c_rock, o_c_paper, o_c_scissors);
      chk(got_p == sel,     "player lamp not the pressed button");
      chk(got_c != CH_NONE, "CPU never chose");
      if (got_p == got_c) begin
        chk(o_draw && !o_win && !o_lose, "tied throws did not light o_draw");
        seen_draw = 1'b1;
      end else if (beats(got_p, got_c)) begin
        chk(o_win && !o_lose && !o_draw, "winning throw did not light o_win");
        exp_p = exp_p + 4'd1;
        seen_win = 1'b1;
      end else begin
        chk(o_lose && !o_win && !o_draw, "losing throw did not light o_lose");
        exp_c = exp_c + 4'd1;
        seen_lose = 1'b1;
      end
      chk(o_score_p == exp_p, "player score off after round");
      chk(o_score_c == exp_c, "CPU score off after round");
    end
    chk(seen_win,  "no round ever produced a player win");
    chk(seen_draw, "no round ever produced a draw");
    chk(seen_lose, "no round ever produced a loss");

    // chord presses: rock outranks paper outranks scissors
    btn_rock = 1; btn_paper = 1;
    repeat (4) @(posedge clk);
    btn_rock = 0; btn_paper = 0;
    repeat (8) @(posedge clk);
    chk(o_p_rock, "rock did not win the rock+paper chord");

    btn_paper = 1; btn_scissors = 1;
    repeat (4) @(posedge clk);
    btn_paper = 0; btn_scissors = 0;
    repeat (8) @(posedge clk);
    chk(o_p_paper, "paper did not win the paper+scissors chord");

    // btn_new darkens the whole table
    press_new;
    repeat (4) @(posedge clk);
    chk(!o_p_rock && !o_p_paper && !o_p_scissors, "player lamps survive btn_new");
    chk(!o_c_rock && !o_c_paper && !o_c_scissors, "CPU lamps survive btn_new");
    chk(!o_win && !o_lose && !o_draw,             "result lamps survive btn_new");
    chk(o_score_p == 4'd0 && o_score_c == 4'd0,   "scores survive btn_new");

    // en low freezes the game: a throw while frozen must vanish
    en = 1'b0;
    throw(CH_ROCK);
    repeat (4) @(posedge clk);
    en = 1'b1;
    repeat (8) @(posedge clk);
    chk(!o_p_rock && !o_p_paper && !o_p_scissors, "throw landed while en was low");

    // ...and the game still lives afterwards
    throw(CH_SCIS);
    repeat (4) @(posedge clk);
    chk(o_p_scissors, "game dead after the en freeze");

    if (errors == 0) $display("PASS: tb_game_rps_lite (0 errors)");
    else             $display("FAIL: tb_game_rps_lite (%0d errors)", errors);
    $finish;
  end

  initial begin
    #1_000_000;
    $display("FAIL: tb_game_rps_lite global timeout");
    $finish;
  end

endmodule
