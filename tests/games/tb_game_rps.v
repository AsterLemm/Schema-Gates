// ============================================================================
// tb_game_rps.v -- self-checking testbench for game_rps
// ----------------------------------------------------------------------------
// Run:  iverilog -g2001 -o tb src/games/game_rps.v \
//                          tests/games/tb_game_rps.v  &&  vvp tb
// Prints one final PASS/FAIL line.  Simulation only -- not synthesizable.
//
// The CPU samples a free-running mod-3 counter at the instant of the throw,
// so phase-shifting each press by 0/1/2 extra clocks walks the CPU through
// every choice.  For each round the TB reads back what the player and CPU
// actually threw and re-derives the expected result and score delta from the
// rock>scissors>paper>rock rule, so it never assumes a particular CPU pick.
// Codes: choice 0 rock / 1 paper / 2 scissors / 3 none;
//        result 0 idle / 1 draw / 2 player won / 3 CPU won.
// ============================================================================
`timescale 1ns/1ns

module tb_game_rps;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg en  = 1'b1;
  reg btn_rock = 1'b0, btn_paper = 1'b0, btn_scissors = 1'b0, btn_new = 1'b0;

  wire [5:0] px_x;
  wire [4:0] px_y;
  wire       px_en, px_clear, px_fill, frame;
  wire [1:0] o_player, o_cpu, o_result;
  wire [3:0] o_score_p, o_score_c;

  game_rps dut (
    .clk(clk), .rst(rst), .en(en),
    .btn_rock(btn_rock), .btn_paper(btn_paper), .btn_scissors(btn_scissors),
    .btn_new(btn_new),
    .px_x(px_x), .px_y(px_y), .px_en(px_en), .px_clear(px_clear),
    .px_fill(px_fill), .frame(frame),
    .o_player(o_player), .o_cpu(o_cpu), .o_result(o_result),
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

  // does choice a beat choice b? (rock>scissors, paper>rock, scissors>paper)
  function beats;
    input [1:0] a, b;
    begin
      beats = ((a==2'd0) && (b==2'd2)) ||
              ((a==2'd1) && (b==2'd0)) ||
              ((a==2'd2) && (b==2'd1));
    end
  endfunction

  // throw choice c (0/1/2) by pulsing the matching button
  task throw;
    input [1:0] c;
    begin
      case (c)
        2'd0: btn_rock     = 1'b1;
        2'd1: btn_paper    = 1'b1;
        default: btn_scissors = 1'b1;
      endcase
      repeat (4) @(posedge clk);
      btn_rock = 1'b0; btn_paper = 1'b0; btn_scissors = 1'b0;
      repeat (4) @(posedge clk);
    end
  endtask

  task press_new; begin btn_new = 1; repeat (4) @(posedge clk); btn_new = 0; repeat (4) @(posedge clk); end endtask

  // pixel-bus invariants, every clock
  always @(posedge clk) begin
    if (!rst && en) begin
      if (px_en && px_clear)   begin errors = errors + 1; $display("FAIL: px_en during px_clear (t=%0t)", $time); end
      if (px_clear && px_fill) begin errors = errors + 1; $display("FAIL: px_clear and px_fill together (t=%0t)", $time); end
      if (px_en && (px_x > 6'd39 || px_y > 5'd23)) begin
        errors = errors + 1; $display("FAIL: lit pixel out of the 40x24 field (t=%0t)", $time); end
    end
  end

  // one round: throw sel with k phase clocks, then verify outputs + score delta
  task round;
    input [1:0] sel;
    input integer k;
    integer sp0, sc0, exp_res, exp_sp, exp_sc;
    begin
      sp0 = o_score_p; sc0 = o_score_c;
      repeat (k) @(posedge clk);
      throw(sel);
      repeat (4) @(posedge clk);
      chk(o_player == sel, "player choice not the pressed button");
      chk(o_cpu <= 2'd2,   "CPU choice out of range");

      if (o_player == o_cpu)            exp_res = 2'd1;   // draw
      else if (beats(o_player, o_cpu))  exp_res = 2'd2;   // player won
      else                              exp_res = 2'd3;   // CPU won
      chk(o_result == exp_res, "result not consistent with the throws");

      exp_sp = (exp_res == 2'd2) ? ((sp0 == 15) ? 15 : sp0 + 1) : sp0;
      exp_sc = (exp_res == 2'd3) ? ((sc0 == 15) ? 15 : sc0 + 1) : sc0;
      chk(o_score_p == exp_sp[3:0], "player score wrong after round");
      chk(o_score_c == exp_sc[3:0], "CPU score wrong after round");
    end
  endtask

  integer r;
  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    repeat (8) @(posedge clk);

    chk(o_player == 2'd3, "player not 'none' after reset");
    chk(o_cpu    == 2'd3, "CPU not 'none' after reset");
    chk(o_result == 2'd0, "result not idle after reset");
    chk(o_score_p == 4'd0 && o_score_c == 4'd0, "scores not zero after reset");

    // nine rounds, cycling the throw and the CPU phase to cover every matchup
    for (r = 0; r < 9; r = r + 1)
      round((r % 3), (r % 3));

    // chord press: rock outranks paper outranks scissors on the same edge
    btn_rock = 1; btn_paper = 1; btn_scissors = 1;
    repeat (4) @(posedge clk);
    btn_rock = 0; btn_paper = 0; btn_scissors = 0;
    repeat (4) @(posedge clk);
    chk(o_player == 2'd0, "chord press did not resolve to rock");

    // btn_new clears the table
    press_new;
    chk(o_player == 2'd3 && o_cpu == 2'd3, "throws survived btn_new");
    chk(o_result == 2'd0, "result not idle after btn_new");
    chk(o_score_p == 4'd0 && o_score_c == 4'd0, "scores survived btn_new");

    // en low freezes scoring
    en = 1'b0;
    throw(2'd0);
    en = 1'b1;
    repeat (8) @(posedge clk);
    chk(o_result == 2'd0 && o_score_p == 4'd0 && o_score_c == 4'd0,
        "round registered while en was low");

    if (errors == 0) $display("PASS: tb_game_rps (0 errors)");
    else             $display("FAIL: tb_game_rps (%0d errors)", errors);
    $finish;
  end

  initial begin
    #2_000_000;
    $display("FAIL: tb_game_rps global timeout");
    $finish;
  end

endmodule
