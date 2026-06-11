// ============================================================================
// tb_game_minesweeper.v -- self-checking testbench for game_minesweeper
// ----------------------------------------------------------------------------
// Run:  iverilog -g2001 -o tb src/games/game_minesweeper.v \
//                          tests/games/tb_game_minesweeper.v  &&  vvp tb
// Prints one final PASS/FAIL line.  Simulation only -- not synthesizable.
//
// Covers: reset state (no boom/win, 0 flags), the en freeze, flag toggling
// before the first reveal, a flag blocking the reveal underneath it (shown
// by the flag still toggling off afterwards -- a revealed cell would refuse
// the toggle), the always-safe first reveal, the revealed-cell flag block,
// and a full row-major sweep that presses reveal on all 64 cells (waiting
// out the mine-scatter and flood-fill passes after each press) which must
// end in exactly one of boom or win.  btn_new then restarts: boom/win and
// the flag count clear and flagging works again.  Always-block invariants:
// px_clear/px_fill exclusivity, px_en never on a clear/fill cycle, frame
// exactly on the clear/fill cycle, and boom/win never together.
//
// Timing notes: one frame is 1025 clocks (32x32 sweep + clear).  After a
// reveal the FSM may spend ~10+ clocks scattering mines (first reveal) and
// up to ~54 flood passes x 64 clocks revealing connected cells, during
// which button presses are ignored -- the bench waits 4096 clocks after
// every reveal before touching the cursor again.
// ============================================================================
`timescale 1ns/1ns

module tb_game_minesweeper;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg en  = 1'b1;
  reg btn_up = 1'b0, btn_down = 1'b0, btn_left = 1'b0, btn_right = 1'b0;
  reg btn_reveal = 1'b0, btn_flag = 1'b0, btn_new = 1'b0;

  wire [4:0] px_x, px_y;
  wire       px_en, px_clear, px_fill, frame;
  wire [3:0] o_flags;
  wire       o_boom, o_win;

  game_minesweeper dut (
    .clk(clk), .rst(rst), .en(en),
    .btn_up(btn_up), .btn_down(btn_down), .btn_left(btn_left),
    .btn_right(btn_right), .btn_reveal(btn_reveal), .btn_flag(btn_flag),
    .btn_new(btn_new),
    .px_x(px_x), .px_y(px_y), .px_en(px_en), .px_clear(px_clear),
    .px_fill(px_fill), .frame(frame),
    .o_flags(o_flags), .o_boom(o_boom), .o_win(o_win)
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
  task press_up;     begin btn_up     = 1; repeat (4) @(posedge clk); btn_up     = 0; repeat (4) @(posedge clk); end endtask
  task press_down;   begin btn_down   = 1; repeat (4) @(posedge clk); btn_down   = 0; repeat (4) @(posedge clk); end endtask
  task press_left;   begin btn_left   = 1; repeat (4) @(posedge clk); btn_left   = 0; repeat (4) @(posedge clk); end endtask
  task press_right;  begin btn_right  = 1; repeat (4) @(posedge clk); btn_right  = 0; repeat (4) @(posedge clk); end endtask
  task press_flag;   begin btn_flag   = 1; repeat (4) @(posedge clk); btn_flag   = 0; repeat (8) @(posedge clk); end endtask
  task press_new;    begin btn_new    = 1; repeat (4) @(posedge clk); btn_new    = 0; repeat (8) @(posedge clk); end endtask

  // reveal, then sit out the worst-case mine scatter + flood-fill cascade
  task press_reveal;
    begin
      btn_reveal = 1; repeat (4) @(posedge clk);
      btn_reveal = 0; repeat (4096) @(posedge clk);
    end
  endtask

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
      if (o_boom && o_win)
        begin errors = errors + 1; $display("FAIL: o_boom and o_win together (t=%0t)", $time); end
    end
  end

  integer f_mark;
  integer x, y;

  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    wait_frames(2);

    // reset state: waiting for the first reveal
    chk(!o_boom && !o_win,  "boom/win set after reset");
    chk(o_flags == 4'd0,    "flag count not 0 after reset");

    // en freeze: raster stops dead
    en = 1'b0;
    f_mark = fcount;
    repeat (4000) @(posedge clk);    // > 3 frame periods
    chk(fcount == f_mark, "frame pulsed while en was low");
    en = 1'b1;

    // flag the start cell (3,3) before any reveal
    press_flag;
    chk(o_flags == 4'd1, "flag did not place on the start cell");

    // a reveal under a flag must be ignored: still no game, and -- the
    // give-away -- the flag still toggles OFF, which a revealed cell would
    // refuse
    press_reveal;
    chk(!o_boom && !o_win, "blocked reveal started the game");
    chk(o_flags == 4'd1,   "flag lost by a blocked reveal");
    press_flag;
    chk(o_flags == 4'd0,   "flag stuck after the blocked reveal");

    // first reveal on the now-unflagged cell: always safe by construction
    press_reveal;
    chk(!o_boom, "first reveal hit a mine (must be safe)");
    chk(!o_win,  "win directly after the first reveal");

    // the revealed cell refuses a flag
    press_flag;
    chk(o_flags == 4'd0, "flag landed on a revealed cell");

    // full sweep: cursor to (0,0), then reveal every cell row-major,
    // wrapping right at each row end and stepping down a row.  Stop
    // pressing once the game has decided.
    press_left;  press_left;  press_left;
    press_up;    press_up;    press_up;
    for (y = 0; y < 8; y = y + 1) begin
      for (x = 0; x < 8; x = x + 1) begin
        if (!o_boom && !o_win) press_reveal;
        if (!o_boom && !o_win) press_right;     // wraps 7 -> 0
      end
      if (!o_boom && !o_win) press_down;
    end
    chk(o_boom ^ o_win, "sweep of all 64 cells decided nothing (or both)");

    // restart: result and flags clear, flagging works again
    press_new;
    chk(!o_boom && !o_win, "boom/win survive btn_new");
    chk(o_flags == 4'd0,   "flag count survives btn_new");
    press_flag;
    chk(o_flags == 4'd1, "flagging dead after btn_new");
    press_flag;
    chk(o_flags == 4'd0, "unflagging dead after btn_new");

    if (errors == 0) $display("PASS: tb_game_minesweeper (0 errors)");
    else             $display("FAIL: tb_game_minesweeper (%0d errors)", errors);
    $finish;
  end

  initial begin
    #20_000_000;
    $display("FAIL: tb_game_minesweeper global timeout");
    $finish;
  end

endmodule
