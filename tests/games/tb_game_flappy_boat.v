// ============================================================================
// tb_game_flappy_boat.v -- self-checking testbench for game_flappy_boat
// ----------------------------------------------------------------------------
// Run:  iverilog -g2001 -o tb src/games/game_flappy_boat.v \
//                          tests/games/tb_game_flappy_boat.v  &&  vvp tb
// Prints one final PASS/FAIL line.  Simulation only -- not synthesizable.
//
// Covers: the READY bobbing state after reset, flap-to-launch, the
// unattended drop into the water (dead well inside 64 frames, score still
// 0 -- the first pillar is 26 columns out), the 60-frame restart lockout
// in the DEAD state, the flap restart after the lockout, and btn_new.
// ============================================================================
`timescale 1ns/1ns

module tb_game_flappy_boat;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg en  = 1'b1;
  reg btn_flap = 1'b0, btn_new = 1'b0;

  wire [5:0] px_x;
  wire [4:0] px_y;
  wire       px_en, px_clear, px_fill, frame;
  wire [7:0] o_score;
  wire       o_dead, o_playing;

  game_flappy_boat dut (
    .clk(clk), .rst(rst), .en(en),
    .btn_flap(btn_flap), .btn_new(btn_new),
    .px_x(px_x), .px_y(px_y), .px_en(px_en), .px_clear(px_clear),
    .px_fill(px_fill), .frame(frame),
    .o_score(o_score), .o_dead(o_dead), .o_playing(o_playing)
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

  task press_flap; begin btn_flap = 1; repeat (4) @(posedge clk); btn_flap = 0; repeat (4) @(posedge clk); end endtask
  task press_new;  begin btn_new  = 1; repeat (4) @(posedge clk); btn_new  = 0; repeat (4) @(posedge clk); end endtask

  // wait until o_dead or maxf frames have passed
  task wait_dead;
    input integer maxf;
    integer k;
    begin
      k = 0;
      while (!o_dead && (k < maxf)) begin
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
      if (o_dead && o_playing) begin errors = errors + 1; $display("FAIL: dead and playing together (t=%0t)", $time); end
    end
  end

  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    wait_frames(2);

    chk(!o_playing && !o_dead, "not in READY after reset");
    chk(o_score == 8'd0, "score not 0 after reset");

    // first flap launches the run
    press_flap;
    wait_frames(2);
    chk(o_playing, "flap did not start the game");
    chk(!o_dead, "dead at launch");

    // hands off: gravity drops the boat into the water, no pillar reached
    wait_dead(64);
    chk(o_dead, "no water death within 64 frames");
    chk(!o_playing, "still playing while dead");
    chk(o_score == 8'd0, "scored without passing a pillar");

    // restart lockout: a flap in the first 60 dead frames is swallowed
    press_flap;
    wait_frames(3);
    chk(o_dead, "flap restarted inside the lockout window");

    // after the lockout a flap returns to READY...
    wait_frames(70);
    press_flap;
    wait_frames(3);
    chk(!o_dead, "flap after lockout did not leave DEAD");
    chk(!o_playing, "restart skipped the READY state");
    chk(o_score == 8'd0, "score survived the restart");

    // ...and the next flap launches again
    press_flap;
    wait_frames(2);
    chk(o_playing, "second run never started");

    // btn_new bails out of a live run immediately
    press_new;
    wait_frames(2);
    chk(!o_playing && !o_dead, "btn_new did not return to READY");
    chk(o_score == 8'd0, "score survived btn_new");

    if (errors == 0) $display("PASS: tb_game_flappy_boat (0 errors)");
    else             $display("FAIL: tb_game_flappy_boat (%0d errors)", errors);
    $finish;
  end

  initial begin
    #5_000_000;
    $display("FAIL: tb_game_flappy_boat global timeout");
    $finish;
  end

endmodule
