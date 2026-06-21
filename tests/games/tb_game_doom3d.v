// ============================================================================
// tb_game_doom3d.v -- self-checking testbench for game_doom3d
// ----------------------------------------------------------------------------
// Run:  iverilog -g2001 -o tb src/games/game_doom3d.v \
//                          tests/games/tb_game_doom3d.v  &&  vvp tb
// Prints one final PASS/FAIL line.  Simulation only -- not synthesizable.
//
// Covers: reset state (entrance cell (2,2) at 0x280/0x280, heading east,
// not won), the en freeze (no frames, no movement even with btn_fwd held),
// the one-frame muzzle flash (px_fill instead of px_clear on the frame
// after btn_fire, back to px_clear on the next), a wall blocking forward
// motion, and a full scripted walk of the maze to the exit at (13,13):
// every leg and turn is checked against position/heading values from an
// exact software model of the movement RTL (sinlut cardinals, axis-
// separated sliding, 0x40/frame walk, +-2/frame turn).  After the win the
// bench shows movement and turning are frozen, then btn_new restarts from
// the entrance and a 2-frame walk shows the game is live again.
// Always-block invariants: px_clear/px_fill exclusivity, px_en never on
// the clear/fill cycle, frame exactly the clear/fill cycle, and -- via a
// bench copy of the maze ROM -- the player's cell is never a wall.
//
// Button protocol (frame-exact): frames are variable length here (rays
// are cast between sweeps), so each walk/turn task first aligns on a
// frame pulse (the M_CLEAR cycle), raises its level button -- the 2-flop
// sync settles ~1022 clocks before the next M_MOVE -- then holds through
// exactly N further frame pulses (= N applied moves) and releases, again
// a full sweep away from the following move.  The alignment frame itself
// is buttonless, so consecutive segments cannot bleed into each other.
// ============================================================================
`timescale 1ns/1ns

module tb_game_doom3d;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg en  = 1'b1;
  reg btn_fwd = 1'b0, btn_back = 1'b0, btn_left = 1'b0, btn_right = 1'b0;
  reg btn_fire = 1'b0, btn_new = 1'b0;

  wire [4:0]  px_x, px_y;
  wire        px_en, px_clear, px_fill, frame;
  wire [11:0] o_posx, o_posy;
  wire [7:0]  o_ang;
  wire        o_win;

  game_doom3d dut (
    .clk(clk), .rst(rst), .en(en),
    .btn_fwd(btn_fwd), .btn_back(btn_back),
    .btn_left(btn_left), .btn_right(btn_right),
    .btn_fire(btn_fire), .btn_new(btn_new),
    .px_x(px_x), .px_y(px_y), .px_en(px_en), .px_clear(px_clear),
    .px_fill(px_fill), .frame(frame),
    .o_posx(o_posx), .o_posy(o_posy), .o_ang(o_ang), .o_win(o_win)
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

  // Each task drives its own named button reg (an inout-arg task does not
  // work in Verilog-2001: copy-in/copy-out would hide the level from the
  // DUT).  Align on a frame pulse, hold through exactly n more pulses.
  task walk_fwd;
    input integer n;
    begin
      wait_frame;
      btn_fwd = 1'b1;
      wait_frames(n);
      btn_fwd = 1'b0;
    end
  endtask

  task turn_left;
    input integer n;
    begin
      wait_frame;
      btn_left = 1'b1;
      wait_frames(n);
      btn_left = 1'b0;
    end
  endtask

  task turn_right;
    input integer n;
    begin
      wait_frame;
      btn_right = 1'b1;
      wait_frames(n);
      btn_right = 1'b0;
    end
  endtask

  task press_new; begin btn_new = 1; repeat (4) @(posedge clk); btn_new = 0; repeat (8) @(posedge clk); end endtask

  // frame pulses seen so far (for the en-freeze check)
  integer fcount = 0;
  always @(posedge clk) if (frame === 1'b1) fcount = fcount + 1;

  // bench copy of the DUT maze ROM, for the never-in-a-wall invariant
  function [15:0] tb_maprow;
    input [3:0] my;
    begin
      case (my)
      4'd0 : tb_maprow = 16'b1111111111111111;
      4'd1 : tb_maprow = 16'b1000000010000001;
      4'd2 : tb_maprow = 16'b1011111010100001;
      4'd3 : tb_maprow = 16'b1010000010111001;
      4'd4 : tb_maprow = 16'b1010111110001001;
      4'd5 : tb_maprow = 16'b1010100000101001;
      4'd6 : tb_maprow = 16'b1010101111100001;
      4'd7 : tb_maprow = 16'b1000101000101111;
      4'd8 : tb_maprow = 16'b1011101010100001;
      4'd9 : tb_maprow = 16'b1010001010111101;
      4'd10: tb_maprow = 16'b1010111010000001;
      4'd11: tb_maprow = 16'b1010100011111101;
      4'd12: tb_maprow = 16'b1010101000000001;
      4'd13: tb_maprow = 16'b1000001011111101;
      4'd14: tb_maprow = 16'b1000001000000001;
      4'd15: tb_maprow = 16'b1111111111111111;
      endcase
    end
  endfunction

  wire [15:0] tb_mrow   = tb_maprow(o_posy[11:8]);
  wire        tb_inwall = tb_mrow[o_posx[11:8]];

  // invariants, every clock
  always @(posedge clk) begin
    if (!rst && en) begin
      if (px_en && (px_clear || px_fill))
        begin errors = errors + 1; $display("FAIL: px_en on a clear/fill cycle (t=%0t)", $time); end
      if (px_clear && px_fill)
        begin errors = errors + 1; $display("FAIL: px_clear and px_fill together (t=%0t)", $time); end
      if (frame !== (px_clear | px_fill))
        begin errors = errors + 1; $display("FAIL: frame not the clear/fill cycle (t=%0t)", $time); end
      if (tb_inwall)
        begin errors = errors + 1; $display("FAIL: player inside a wall cell (t=%0t)", $time); end
    end
  end

  integer f_mark;

  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    wait_frames(2);

    // reset state: entrance, facing east, not won
    chk(o_posx == 12'h280 && o_posy == 12'h280, "not at the entrance after reset");
    chk(o_ang == 8'd0,                          "heading not east after reset");
    chk(!o_win,                                 "o_win set after reset");

    // en freeze: no frames and no movement, even with fwd held
    en = 1'b0;
    f_mark = fcount;
    btn_fwd = 1'b1;
    repeat (20000) @(posedge clk);   // > 2 worst-case frame periods
    btn_fwd = 1'b0;
    repeat (8) @(posedge clk);
    chk(fcount == f_mark,                       "frame pulsed while en was low");
    chk(o_posx == 12'h280 && o_posy == 12'h280, "moved while en was low");
    en = 1'b1;

    // muzzle flash: btn_fire turns the NEXT clear cycle into a fill,
    // and only that one
    wait_frame;
    btn_fire = 1'b1; repeat (4) @(posedge clk); btn_fire = 1'b0;
    wait_frame;
    chk(px_fill && !px_clear, "btn_fire frame is not a px_fill");
    wait_frame;
    chk(px_clear && !px_fill, "muzzle flash stuck past one frame");

    // ---- scripted maze run, checked against the exact movement model ----
    // headings: ang 0 = +x (east), 64 = +y (south), 128 = -x, 192 = -y.

    walk_fwd(14);                    // leg 1: east along row 2 to the wall
    chk(o_posx == 12'h4C0 && o_posy == 12'h280, "leg 1 east clamp wrong");

    turn_right(32);                  // face south
    chk(o_ang == 8'd64, "heading not south after turn 1");

    walk_fwd(5);                     // wall at (4,3): one half-step then stuck
    chk(o_posx == 12'h4C0 && o_posy == 12'h2C0, "south wall did not block");

    turn_right(64);                  // about-face: north
    chk(o_ang == 8'd192, "heading not north after turn 2");

    walk_fwd(10);                    // leg 2: north to the border row
    chk(o_posx == 12'h4C0 && o_posy == 12'h100, "leg 2 north clamp wrong");

    turn_right(32);                  // east
    chk(o_ang == 8'd0, "heading not east after turn 3");

    walk_fwd(12);                    // leg 3: east along row 1 to (7,1) wall
    chk(o_posx == 12'h6C0 && o_posy == 12'h100, "leg 3 east clamp wrong");

    turn_right(32);                  // south
    chk(o_ang == 8'd64, "heading not south after turn 4");

    walk_fwd(23);                    // leg 4: south down the x=6 corridor
    chk(o_posx == 12'h6C0 && o_posy == 12'h5C0, "leg 4 south clamp wrong");

    turn_left(32);                   // east
    chk(o_ang == 8'd0, "heading not east after turn 5");

    walk_fwd(20);                    // leg 5: east along row 5
    chk(o_posx == 12'hAC0 && o_posy == 12'h5C0, "leg 5 east clamp wrong");

    turn_right(32);                  // south
    chk(o_ang == 8'd64, "heading not south after turn 6");

    walk_fwd(20);                    // leg 6: south down the x=10 corridor
    chk(o_posx == 12'hAC0 && o_posy == 12'h9C0, "leg 6 south clamp wrong");

    turn_left(32);                   // east
    chk(o_ang == 8'd0, "heading not east after turn 7");

    walk_fwd(12);                    // leg 7: east along row 9
    chk(o_posx == 12'hCC0 && o_posy == 12'h9C0, "leg 7 east clamp wrong");

    turn_right(32);                  // south
    chk(o_ang == 8'd64, "heading not south after turn 8");

    walk_fwd(16);                    // leg 8: EXACTLY 16 frames -- no wall
    chk(o_posx == 12'hCC0 && o_posy == 12'hDC0, "leg 8 frame count drifted");

    turn_left(32);                   // east
    chk(o_ang == 8'd0, "heading not east after turn 9");

    walk_fwd(8);                     // leg 9: east into the exit cell
    chk(o_win,                                  "no win at the exit cell");
    // the win latch gates movement from the following frame, so the walk
    // carries one 0x40 step into the exit cell before freezing
    chk(o_posx == 12'hD40 && o_posy == 12'hDC0, "win pos not (13,13) entry");

    // after the win, walking and turning must both be frozen
    walk_fwd(5);
    chk(o_posx == 12'hD40 && o_posy == 12'hDC0, "moved after the win");
    turn_right(5);
    chk(o_ang == 8'd0, "turned after the win");
    chk(o_win,         "o_win dropped on its own");

    // restart: back to the entrance, live again (2 frames east = +0x80)
    press_new;
    chk(o_posx == 12'h280 && o_posy == 12'h280, "btn_new did not re-enter");
    chk(o_ang == 8'd0,                          "btn_new kept the heading");
    chk(!o_win,                                 "o_win survives btn_new");
    walk_fwd(2);
    chk(o_posx == 12'h300 && o_posy == 12'h280, "not walking after btn_new");

    if (errors == 0) $display("PASS: tb_game_doom3d (0 errors)");
    else             $display("FAIL: tb_game_doom3d (%0d errors)", errors);
    $finish;
  end

  initial begin
    #60_000_000;
    $display("FAIL: tb_game_doom3d global timeout");
    $finish;
  end

endmodule
