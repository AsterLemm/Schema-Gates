// ============================================================================
// tb_game_tictactoe_lite.v -- self-checking testbench for game_tictactoe_lite
// ----------------------------------------------------------------------------
// Run:  iverilog -g2001 -o tb src/games/game_tictactoe_lite.v \
//                          tests/games/tb_game_tictactoe_lite.v  &&  vvp tb
// Prints one final PASS/FAIL line.  Simulation only -- not synthesizable.
//
// Covers: reset state (cursor lamp on cell 0, board buses dark), cursor
// navigation with edge clamping on the one-hot o_cur bus, mark placement on
// the o_x / o_o lamp buses, occupied-cell rejection, a full top-row X win
// (o_win, o_winner, the o_line mask), the post-win freeze, btn_new clearing
// the board while keeping the cursor, and the en freeze.  Always-block
// invariants: no cell lit on both o_x and o_o, o_cur exactly one-hot,
// o_line dark unless o_win and never pointing at empty cells, and o_win /
// o_draw never together.
// ============================================================================
`timescale 1ns/1ns

module tb_game_tictactoe_lite;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg en  = 1'b1;
  reg btn_up = 1'b0, btn_down = 1'b0, btn_left = 1'b0, btn_right = 1'b0;
  reg btn_place = 1'b0, btn_new = 1'b0;

  wire [8:0] o_x, o_o, o_cur, o_line;
  wire       o_turn, o_win, o_winner, o_draw;

  game_tictactoe_lite dut (
    .clk(clk), .rst(rst), .en(en),
    .btn_up(btn_up), .btn_down(btn_down), .btn_left(btn_left),
    .btn_right(btn_right), .btn_place(btn_place), .btn_new(btn_new),
    .o_x(o_x), .o_o(o_o), .o_cur(o_cur), .o_line(o_line),
    .o_turn(o_turn), .o_win(o_win), .o_winner(o_winner), .o_draw(o_draw)
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

  // Each press drives its own named button reg.  (A generic task taking the
  // button as an inout arg does NOT work in Verilog-2001: inout args are
  // copy-in/copy-out, so the DUT would never see the button go high while the
  // task blocks on @(posedge clk).)
  task press_up;    begin btn_up    = 1; repeat (4) @(posedge clk); btn_up    = 0; repeat (4) @(posedge clk); end endtask
  task press_down;  begin btn_down  = 1; repeat (4) @(posedge clk); btn_down  = 0; repeat (4) @(posedge clk); end endtask
  task press_left;  begin btn_left  = 1; repeat (4) @(posedge clk); btn_left  = 0; repeat (4) @(posedge clk); end endtask
  task press_right; begin btn_right = 1; repeat (4) @(posedge clk); btn_right = 0; repeat (4) @(posedge clk); end endtask
  task press_place; begin btn_place = 1; repeat (4) @(posedge clk); btn_place = 0; repeat (8) @(posedge clk); end endtask
  task press_new;   begin btn_new   = 1; repeat (4) @(posedge clk); btn_new   = 0; repeat (8) @(posedge clk); end endtask

  // invariants, every clock
  always @(posedge clk) begin
    if (!rst && en) begin
      if ((o_x & o_o) != 9'd0)
        begin errors = errors + 1; $display("FAIL: cell lit as both X and O (t=%0t)", $time); end
      if (o_cur[0] + o_cur[1] + o_cur[2] + o_cur[3] + o_cur[4]
        + o_cur[5] + o_cur[6] + o_cur[7] + o_cur[8] != 1)
        begin errors = errors + 1; $display("FAIL: cursor lamp not one-hot (t=%0t)", $time); end
      if (!o_win && o_line != 9'd0)
        begin errors = errors + 1; $display("FAIL: o_line lit without a win (t=%0t)", $time); end
      if ((o_line & ~(o_x | o_o)) != 9'd0)
        begin errors = errors + 1; $display("FAIL: o_line points at empty cells (t=%0t)", $time); end
      if (o_win && o_draw)
        begin errors = errors + 1; $display("FAIL: o_win and o_draw together (t=%0t)", $time); end
    end
  end

  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    repeat (8) @(posedge clk);

    // reset state: dark board, cursor lamp on cell 0, X to move
    chk(o_x == 9'd0 && o_o == 9'd0,  "board buses lit after reset");
    chk(o_cur == 9'h001,             "cursor lamp not on cell 0 after reset");
    chk(o_line == 9'd0,              "o_line lit after reset");
    chk(!o_turn,                     "not X's turn after reset");
    chk(!o_win && !o_draw,           "win/draw lit after reset");

    // cursor navigation + edge clamp on the one-hot lamp bus
    press_right; chk(o_cur == 9'h002, "right: cursor lamp not on cell 1");
    press_down;  chk(o_cur == 9'h010, "down: cursor lamp not on cell 4");
    press_up;    chk(o_cur == 9'h002, "up: cursor lamp not on cell 1");
    press_up;    chk(o_cur == 9'h002, "cursor escaped the top edge");
    press_left;  chk(o_cur == 9'h001, "left: cursor lamp not on cell 0");

    // X takes cell 0
    press_place;
    chk(o_x == 9'h001 && o_o == 9'd0, "X lamp 0 not lit after place");
    chk(o_turn,                       "turn did not pass to O");

    // occupied cell rejects the place (O must not land on cell 0)
    press_place;
    chk(o_x == 9'h001 && o_o == 9'd0, "occupied cell accepted a mark");
    chk(o_turn,                       "turn moved on a rejected place");

    // O takes cell 3
    press_down;
    chk(o_cur == 9'h008, "down: cursor lamp not on cell 3");
    press_place;
    chk(o_o == 9'h008,   "O lamp 3 not lit after place");
    chk(!o_turn,         "turn did not pass back to X");

    // X takes cell 1, O takes cell 4, X takes cell 2 -> top row win
    press_up; press_right;
    chk(o_cur == 9'h002, "cursor lamp not on cell 1");
    press_place;
    chk(o_x == 9'h003,   "X lamps not 0+1 after second X");
    press_down;
    chk(o_cur == 9'h010, "cursor lamp not on cell 4");
    press_place;
    chk(o_o == 9'h018,   "O lamps not 3+4 after second O");
    press_up; press_right;
    chk(o_cur == 9'h004, "cursor lamp not on cell 2");
    press_place;
    repeat (4) @(posedge clk);       // result detect lags the move by a cycle

    chk(o_x == 9'h007,          "X lamps not the full top row");
    chk(o_win,                  "top row did not light o_win");
    chk(!o_winner,              "o_winner not X for an X win");
    chk(!o_draw,                "draw lit on a win");
    chk(o_line == 9'h007,       "o_line is not the top row");

    // board frozen after the win
    press_down;                      // cursor still moves (cell 5)...
    chk(o_cur == 9'h020, "cursor stuck after the win");
    press_place;                     // ...but marks no longer land
    chk(o_x == 9'h007 && o_o == 9'h018, "mark landed after the win");

    // btn_new: board + result clear, cursor lamp stays put
    press_new;
    chk(o_x == 9'd0 && o_o == 9'd0, "board lamps survive btn_new");
    chk(o_line == 9'd0,             "o_line survives btn_new");
    chk(!o_win && !o_draw,          "win/draw survive btn_new");
    chk(!o_turn,                    "not X's turn after btn_new");
    chk(o_cur == 9'h020,            "btn_new moved the cursor lamp");

    // en low freezes everything, even the cursor
    en = 1'b0;
    press_left;
    en = 1'b1;
    repeat (8) @(posedge clk);
    chk(o_cur == 9'h020, "cursor moved while en was low");

    // ...and the game still lives afterwards
    press_left;
    chk(o_cur == 9'h010, "game dead after the en freeze");
    press_place;
    chk(o_x == 9'h010,   "place dead after the en freeze");

    if (errors == 0) $display("PASS: tb_game_tictactoe_lite (0 errors)");
    else             $display("FAIL: tb_game_tictactoe_lite (%0d errors)", errors);
    $finish;
  end

  initial begin
    #1_000_000;
    $display("FAIL: tb_game_tictactoe_lite global timeout");
    $finish;
  end

endmodule
