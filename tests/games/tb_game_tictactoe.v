// ============================================================================
// tb_game_tictactoe.v -- self-checking testbench for game_tictactoe
// ----------------------------------------------------------------------------
// Run:  iverilog -g2001 -o tb src/games/game_tictactoe.v \
//                          tests/games/tb_game_tictactoe.v  &&  vvp tb
// Prints one final PASS/FAIL line.  Simulation only -- not synthesizable.
//
// Covers: reset state (dark board, X to move, cursor at (0,0)), turn order,
// occupied-cell rejection, a full top-row X win (o_win / o_winner / o_draw),
// the post-win freeze, btn_new clearing the board, the en freeze, and the
// games-family pixel-bus contract (px_en/px_clear mutual exclusion,
// px_clear/px_fill mutual exclusion, coordinates in range, frames running).
//
// 2-bit cell read: cell i is o_board[2i+1:2i], 00 empty 01 X 10 O, with
// i = row*3 + col (row 0 at the top, col 0 on the left).
// ============================================================================
`timescale 1ns/1ns

module tb_game_tictactoe;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg en  = 1'b1;
  reg btn_up = 1'b0, btn_down = 1'b0, btn_left = 1'b0, btn_right = 1'b0;
  reg btn_place = 1'b0, btn_new = 1'b0;

  wire [4:0]  px_x, px_y;
  wire        px_en, px_clear, px_fill, frame;
  wire [17:0] o_board;
  wire        o_turn, o_win, o_winner, o_draw;

  game_tictactoe dut (
    .clk(clk), .rst(rst), .en(en),
    .btn_up(btn_up), .btn_down(btn_down), .btn_left(btn_left),
    .btn_right(btn_right), .btn_place(btn_place), .btn_new(btn_new),
    .px_x(px_x), .px_y(px_y), .px_en(px_en), .px_clear(px_clear),
    .px_fill(px_fill), .frame(frame),
    .o_board(o_board), .o_turn(o_turn), .o_win(o_win),
    .o_winner(o_winner), .o_draw(o_draw)
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

  // 2-bit read of cell i straight off the o_board bus
  function [1:0] bcell;
    input [3:0] i;
    begin
      bcell = o_board >> {i, 1'b0};
    end
  endfunction

  task wait_frame;
    begin
      @(posedge clk);
      while (frame !== 1'b1) @(posedge clk);
    end
  endtask

  // Each press drives its own named button reg (inout task args are
  // copy-in/copy-out in Verilog-2001 and would never reach the DUT).
  task press_up;    begin btn_up    = 1; repeat (4) @(posedge clk); btn_up    = 0; repeat (4) @(posedge clk); end endtask
  task press_down;  begin btn_down  = 1; repeat (4) @(posedge clk); btn_down  = 0; repeat (4) @(posedge clk); end endtask
  task press_left;  begin btn_left  = 1; repeat (4) @(posedge clk); btn_left  = 0; repeat (4) @(posedge clk); end endtask
  task press_right; begin btn_right = 1; repeat (4) @(posedge clk); btn_right = 0; repeat (4) @(posedge clk); end endtask
  task press_place; begin btn_place = 1; repeat (4) @(posedge clk); btn_place = 0; repeat (8) @(posedge clk); end endtask
  task press_new;   begin btn_new   = 1; repeat (4) @(posedge clk); btn_new   = 0; repeat (8) @(posedge clk); end endtask

  // pixel-bus invariants, every clock
  integer ci;
  always @(posedge clk) begin
    if (!rst && en) begin
      if (px_en && px_clear)   begin errors = errors + 1; $display("FAIL: px_en during px_clear (t=%0t)", $time); end
      if (px_clear && px_fill) begin errors = errors + 1; $display("FAIL: px_clear and px_fill together (t=%0t)", $time); end
      if (px_en && (px_x > 5'd23 || px_y > 5'd23)) begin
        errors = errors + 1; $display("FAIL: lit pixel out of the 24x24 field (t=%0t)", $time); end
      // no cell may ever hold the illegal code 2'b11
      for (ci = 0; ci < 9; ci = ci + 1)
        if (bcell(ci[3:0]) == 2'b11) begin
          errors = errors + 1; $display("FAIL: illegal cell code 11 (t=%0t)", $time); end
    end
  end

  // frames must actually be produced
  reg saw_frame = 1'b0;
  always @(posedge clk) if (frame) saw_frame <= 1'b1;

  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    wait_frame; wait_frame;

    chk(o_board == 18'd0,  "board not clear after reset");
    chk(!o_turn,           "not X's turn after reset");
    chk(!o_win && !o_draw, "win/draw set after reset");
    chk(saw_frame,         "no frame pulse seen after reset");

    // X takes cell 0 (cursor starts at (0,0))
    press_place;
    chk(bcell(0) == 2'b01, "X not placed in cell 0");
    chk(o_turn,           "turn did not pass to O");

    // occupied cell rejects the place
    press_place;
    chk(bcell(0) == 2'b01, "occupied cell accepted a mark");
    chk(o_turn,           "turn moved on a rejected place");

    // O takes cell 3 = (col 0,row 1)
    press_down;
    press_place;
    chk(bcell(3) == 2'b10, "O not placed in cell 3");
    chk(!o_turn,          "turn did not pass back to X");

    // X cell 1 -> O cell 4 -> X cell 2 : top-row X win
    press_up; press_right;             // cursor 0,0 -> 1,0 = cell 1
    press_place;
    chk(bcell(1) == 2'b01, "second X not in cell 1");
    press_down;                        // cell 4
    press_place;
    chk(bcell(4) == 2'b10, "second O not in cell 4");
    press_up; press_right;             // cursor 1,0 -> 2,0 = cell 2
    press_place;
    wait_frame; wait_frame;            // result detect lags the move

    chk(bcell(0)==2'b01 && bcell(1)==2'b01 && bcell(2)==2'b01, "top row is not all X");
    chk(o_win,            "top row did not raise o_win");
    chk(!o_winner,        "o_winner not X for an X win");
    chk(!o_draw,          "draw raised on a win");

    // frozen after the win: a place must not land
    press_place;
    chk(bcell(5) == 2'b00, "a mark landed after the win");

    // btn_new clears the board
    press_new;
    chk(o_board == 18'd0,  "board survived btn_new");
    chk(!o_win && !o_draw, "win/draw survived btn_new");
    chk(!o_turn,           "not X's turn after btn_new");

    // en low freezes the game
    press_place;                       // X would normally take bcell 2 here
    chk(bcell(2) == 2'b01, "place dead right after btn_new");
    en = 1'b0;
    press_place;                       // O attempt, but frozen
    en = 1'b1;
    repeat (8) @(posedge clk);
    chk(bcell(2) == 2'b01 && o_turn, "state changed while en was low");

    if (errors == 0) $display("PASS: tb_game_tictactoe (0 errors)");
    else             $display("FAIL: tb_game_tictactoe (%0d errors)", errors);
    $finish;
  end

  initial begin
    #2_000_000;
    $display("FAIL: tb_game_tictactoe global timeout");
    $finish;
  end

endmodule
