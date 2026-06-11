// ============================================================================
// tb_game_chess.v -- self-checking testbench for game_chess
// ----------------------------------------------------------------------------
// Run:  iverilog -g2001 -o tb src/games/game_chess.v \
//                          tests/games/tb_game_chess.v  &&  vvp tb
// Prints one final PASS/FAIL line.  Simulation only -- not synthesizable.
//
// Covers: reset state (cursor on the white e-pawn at (4,6), white to move,
// nothing selected), the en freeze (no frames, a press while frozen is
// lost), cursor wrap (down off the bottom lands on the black king at
// (4,0)), select refusals (enemy piece, empty square), select / deselect /
// reselect with o_src tracking, an illegal destination keeping the
// selection, and a complete scripted game in which white hunts the black
// king with the queen:
//      W1 e-pawn (4,6)-(4,4) double push     B1 a-pawn (0,1)-(0,2)
//      W2 queen  (3,7)-(7,3) diagonal        B2 a-pawn (0,2)-(0,3)
//      W3 queen  (7,3)x(5,1) pawn capture    B3 a-pawn (0,3)-(0,4)
//      W4 queen  (5,1)x(4,0) KING CAPTURE -> o_over, white wins
// Every move checks o_turn handover and the piece code now under the
// cursor.  After the king falls: cursor and select are frozen, btn_new
// re-racks the board (the black king reappears under the cursor) but
// keeps the cursor where it was, and the cursor moves again.
// Always-block invariants: px_clear/px_fill exclusivity, px_en never on
// the clear/fill cycle, frame exactly the clear/fill cycle.
//
// Board/piece notation used below: squares are (x,y) with black on rows
// y=0..1 and white on y=6..7; o_cursor and o_src pack as {y[2:0],x[2:0]}.
// Piece codes {colour,type}: 4'h1 white pawn, 4'h5 white queen, 4'h6
// white king, 4'h9 black pawn, 4'hE black king, 4'h0 empty.  The FSM is
// pulse-driven (no frame gating), so the bench needs no frame waits
// between presses; one frame is 4097 clocks (64x64 sweep + clear).
// ============================================================================
`timescale 1ns/1ns

module tb_game_chess;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg en  = 1'b1;
  reg btn_up = 1'b0, btn_down = 1'b0, btn_left = 1'b0, btn_right = 1'b0;
  reg btn_sel = 1'b0, btn_new = 1'b0;

  wire [5:0] px_x, px_y;
  wire       px_en, px_clear, px_fill, frame;
  wire       o_turn, o_over, o_winner, o_sel;
  wire [5:0] o_src, o_cursor;
  wire [3:0] o_piece;

  game_chess dut (
    .clk(clk), .rst(rst), .en(en),
    .btn_up(btn_up), .btn_down(btn_down), .btn_left(btn_left),
    .btn_right(btn_right), .btn_sel(btn_sel), .btn_new(btn_new),
    .px_x(px_x), .px_y(px_y), .px_en(px_en), .px_clear(px_clear),
    .px_fill(px_fill), .frame(frame),
    .o_turn(o_turn), .o_over(o_over), .o_winner(o_winner),
    .o_sel(o_sel), .o_src(o_src), .o_cursor(o_cursor), .o_piece(o_piece)
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

  // Each press drives its own named button reg (an inout-arg task does not
  // work in Verilog-2001: copy-in/copy-out would hide the pulse from the DUT).
  task press_up;    begin btn_up    = 1; repeat (4) @(posedge clk); btn_up    = 0; repeat (4) @(posedge clk); end endtask
  task press_down;  begin btn_down  = 1; repeat (4) @(posedge clk); btn_down  = 0; repeat (4) @(posedge clk); end endtask
  task press_left;  begin btn_left  = 1; repeat (4) @(posedge clk); btn_left  = 0; repeat (4) @(posedge clk); end endtask
  task press_right; begin btn_right = 1; repeat (4) @(posedge clk); btn_right = 0; repeat (4) @(posedge clk); end endtask
  task press_sel;   begin btn_sel   = 1; repeat (4) @(posedge clk); btn_sel   = 0; repeat (8) @(posedge clk); end endtask
  task press_new;   begin btn_new   = 1; repeat (4) @(posedge clk); btn_new   = 0; repeat (8) @(posedge clk); end endtask

  task lefts;  input integer n; integer k; begin for (k = 0; k < n; k = k + 1) press_left;  end endtask
  task rights; input integer n; integer k; begin for (k = 0; k < n; k = k + 1) press_right; end endtask
  task ups;    input integer n; integer k; begin for (k = 0; k < n; k = k + 1) press_up;    end endtask
  task downs;  input integer n; integer k; begin for (k = 0; k < n; k = k + 1) press_down;  end endtask

  // frame pulses seen so far (for the en-freeze check)
  integer fcount = 0;
  always @(posedge clk) if (frame === 1'b1) fcount = fcount + 1;

  // invariants, every clock
  always @(posedge clk) begin
    if (!rst && en) begin
      if (px_en && (px_clear || px_fill))
        begin errors = errors + 1; $display("FAIL: px_en on a clear/fill cycle (t=%0t)", $time); end
      if (px_clear && px_fill)
        begin errors = errors + 1; $display("FAIL: px_clear and px_fill together (t=%0t)", $time); end
      if (frame !== (px_clear | px_fill))
        begin errors = errors + 1; $display("FAIL: frame not the clear/fill cycle (t=%0t)", $time); end
    end
  end

  integer f_mark;

  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    wait_frames(2);

    // reset state: cursor on the white e-pawn, white to move
    chk(o_cursor == 6'h34, "cursor not on (4,6) after reset");
    chk(o_piece  == 4'h1,  "no white pawn under the reset cursor");
    chk(!o_turn,           "not white to move after reset");
    chk(!o_over && !o_sel, "over/sel set after reset");

    // en freeze: no frames, and a press while frozen is simply lost
    en = 1'b0;
    f_mark = fcount;
    press_right;
    repeat (13000) @(posedge clk);   // > 3 frame periods
    chk(fcount == f_mark, "frame pulsed while en was low");
    en = 1'b1;
    repeat (8) @(posedge clk);
    chk(o_cursor == 6'h34, "frozen press moved the cursor");

    // cursor wrap straight down: white king, then (wrap) the black king
    press_down;                              // (4,7)
    chk(o_piece == 4'h6, "white king not at (4,7)");
    press_down;                              // wrap -> (4,0)
    chk(o_cursor == 6'h04, "cursor did not wrap 7->0");
    chk(o_piece  == 4'hE,  "black king not at (4,0)");

    // white may not select a black piece
    press_sel;
    chk(!o_sel, "selected an enemy piece");

    // back to the e-pawn (wrapping up), via the black e-pawn
    press_down;                              // (4,1)
    chk(o_piece == 4'h9, "black pawn not at (4,1)");
    ups(3);                                  // (4,0) (4,7) (4,6)
    chk(o_cursor == 6'h34, "cursor not back on (4,6)");

    // selecting an empty square does nothing
    ups(2);                                  // (4,4)
    chk(o_piece == 4'h0, "(4,4) not empty at the start");
    press_sel;
    chk(!o_sel, "selected an empty square");
    downs(2);                                // back to (4,6)

    // ---- W1: e-pawn double push, with select-machinery tests woven in ----
    press_sel;                               // pick up the pawn
    chk(o_sel && o_src == 6'h34, "pawn did not select");
    press_sel;                               // sel on src: put it down
    chk(!o_sel, "sel on the source did not deselect");
    press_sel;                               // pick it up again
    chk(o_sel, "reselect of the pawn failed");
    press_right;                             // (5,6), the f-pawn
    press_sel;                               // own piece: reselect
    chk(o_sel && o_src == 6'h35, "reselect did not move o_src");
    press_left;                              // (4,6)
    press_sel;                               // reselect back
    chk(o_src == 6'h34, "o_src not back on the e-pawn");
    ups(3);                                  // (4,3): a 3-square pawn push
    press_sel;
    chk(o_sel && o_src == 6'h34, "illegal dst dropped the selection");
    chk(!o_turn, "illegal dst handed the turn over");
    press_down;                              // (4,4)
    press_sel;                               // legal double push
    chk(o_turn,          "W1 did not hand the turn to black");
    chk(!o_sel,          "selection survived W1");
    chk(o_piece == 4'h1, "white pawn not on (4,4) after W1");

    // ---- B1: black a-pawn (0,1) -> (0,2) ----
    lefts(4); ups(3);                        // (0,4) then (0,1)
    chk(o_piece == 4'h9, "black a-pawn not at (0,1)");
    press_sel;
    chk(o_sel && o_src == 6'h08, "B1 select failed");
    press_down;                              // (0,2)
    press_sel;
    chk(!o_turn, "B1 did not hand the turn to white");
    chk(!o_sel,  "selection survived B1");

    // ---- W2: queen (3,7) -> (7,3), long open diagonal ----
    rights(3); downs(5);                     // (3,2) then (3,7)
    chk(o_piece == 4'h5, "white queen not at (3,7)");
    press_sel;
    chk(o_sel && o_src == 6'h3B, "W2 queen select failed");
    rights(4); ups(4);                       // (7,7) then (7,3)
    chk(o_piece == 4'h0, "(7,3) not empty before W2");
    press_sel;
    chk(o_turn,          "W2 did not hand the turn to black");
    chk(!o_sel,          "selection survived W2");
    chk(o_piece == 4'h5, "queen not on (7,3) after W2");

    // ---- B2: a-pawn (0,2) -> (0,3) ----
    press_right;                             // wrap 7->0: (0,3)
    press_up;                                // (0,2)
    chk(o_piece == 4'h9, "a-pawn not at (0,2) before B2");
    press_sel;
    press_down;                              // (0,3)
    press_sel;
    chk(!o_turn, "B2 did not hand the turn to white");

    // ---- W3: queen takes the pawn on (5,1) ----
    press_left;                              // wrap 0->7: (7,3)
    chk(o_piece == 4'h5, "queen not found for W3");
    press_sel;
    chk(o_sel && o_src == 6'h1F, "W3 queen select failed");
    lefts(2); ups(2);                        // (5,3) then (5,1)
    chk(o_piece == 4'h9, "no black pawn on (5,1) to take");
    press_sel;
    chk(o_turn,          "W3 capture did not hand the turn over");
    chk(!o_sel,          "selection survived W3");
    chk(o_piece == 4'h5, "queen not on (5,1) after the capture");

    // ---- B3: a-pawn (0,3) -> (0,4) ----
    lefts(5); downs(2);                      // (0,1) then (0,3)
    chk(o_piece == 4'h9, "a-pawn not at (0,3) before B3");
    press_sel;
    press_down;                              // (0,4)
    press_sel;
    chk(!o_turn, "B3 did not hand the turn to white");

    // ---- W4: queen takes the KING on (4,0) ----
    lefts(3); ups(3);                        // (5,4) then (5,1)
    chk(o_piece == 4'h5, "queen not found for W4");
    press_sel;
    press_left;                              // (4,1)
    press_up;                                // (4,0)
    chk(o_piece == 4'hE, "black king not on (4,0) for W4");
    press_sel;                               // off with his head
    chk(o_over,           "king capture did not end the game");
    chk(o_winner == 1'b0, "winner is not white");
    chk(!o_sel,           "selection survived the king capture");
    chk(!o_turn,          "turn flipped on the winning move");

    // the board is dead: cursor and select are frozen
    press_right; press_down;
    chk(o_cursor == 6'h04, "cursor moved after game over");
    press_sel;
    chk(!o_sel && o_over, "select worked after game over");

    // btn_new: fresh board, same cursor -- the king is back under it
    press_new;
    chk(!o_over && !o_turn && !o_sel, "btn_new did not reset the game");
    chk(o_cursor == 6'h04, "btn_new moved the cursor");
    chk(o_piece  == 4'hE,  "black king not re-racked at (4,0)");
    press_down;                              // (4,1)
    chk(o_cursor == 6'h0C, "cursor dead after btn_new");
    chk(o_piece  == 4'h9,  "black pawn not re-racked at (4,1)");

    if (errors == 0) $display("PASS: tb_game_chess (0 errors)");
    else             $display("FAIL: tb_game_chess (%0d errors)", errors);
    $finish;
  end

  initial begin
    #10_000_000;
    $display("FAIL: tb_game_chess global timeout");
    $finish;
  end

endmodule
