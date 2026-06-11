// ============================================================================
// tb_game_life16.v -- self-checking testbench for game_life16
// ----------------------------------------------------------------------------
// Run:  iverilog -g2001 -o tb src/games/game_life16.v \
//                          tests/games/tb_game_life16.v  &&  vvp tb
// Prints one final PASS/FAIL line.  Simulation only -- not synthesizable.
//
// Covers: reset state, btn_clear, btn_toggle on the (8,8) reset cursor,
// single-step death of a lone cell (population -> 0, generation +1), a 3-cell
// blinker holding population 3 across two steps (the period-2 oscillator),
// auto-run advancing the generation and pause freezing it, btn_rand seeding a
// non-empty board with the generation reset, the en freeze, and the pixel-bus
// contract.  Cursor moves wrap on the 16x16 torus.
// ============================================================================
`timescale 1ns/1ns

module tb_game_life16;

  reg clk = 1'b0;
  reg rst = 1'b1;
  reg en  = 1'b1;
  reg btn_run = 0, btn_step = 0, btn_rand = 0, btn_clear = 0, btn_toggle = 0;
  reg btn_up = 0, btn_down = 0, btn_left = 0, btn_right = 0;
  reg [1:0] speed = 2'd3;

  wire [3:0]  px_x, px_y;
  wire        px_en, px_clear, px_fill, frame;
  wire [8:0]  o_pop;
  wire [15:0] o_gen;
  wire        o_running;

  game_life16 dut (
    .clk(clk), .rst(rst), .en(en),
    .btn_run(btn_run), .btn_step(btn_step), .btn_rand(btn_rand),
    .btn_clear(btn_clear), .btn_toggle(btn_toggle),
    .btn_up(btn_up), .btn_down(btn_down), .btn_left(btn_left), .btn_right(btn_right),
    .speed(speed),
    .px_x(px_x), .px_y(px_y), .px_en(px_en), .px_clear(px_clear),
    .px_fill(px_fill), .frame(frame),
    .o_pop(o_pop), .o_gen(o_gen), .o_running(o_running)
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
  task wait_frames; input integer n; integer k; begin for (k=0;k<n;k=k+1) wait_frame; end endtask

  task press_run;    begin btn_run    = 1; repeat (4) @(posedge clk); btn_run    = 0; repeat (4) @(posedge clk); end endtask
  task press_step;   begin btn_step   = 1; repeat (4) @(posedge clk); btn_step   = 0; repeat (4) @(posedge clk); end endtask
  task press_rand;   begin btn_rand   = 1; repeat (4) @(posedge clk); btn_rand   = 0; repeat (4) @(posedge clk); end endtask
  task press_clear;  begin btn_clear  = 1; repeat (4) @(posedge clk); btn_clear  = 0; repeat (4) @(posedge clk); end endtask
  task press_toggle; begin btn_toggle = 1; repeat (4) @(posedge clk); btn_toggle = 0; repeat (4) @(posedge clk); end endtask
  task press_left;   begin btn_left   = 1; repeat (4) @(posedge clk); btn_left   = 0; repeat (4) @(posedge clk); end endtask
  task press_right;  begin btn_right  = 1; repeat (4) @(posedge clk); btn_right  = 0; repeat (4) @(posedge clk); end endtask

  // pixel-bus invariants
  always @(posedge clk) begin
    if (!rst && en) begin
      if (px_en && px_clear)   begin errors = errors + 1; $display("FAIL: px_en during px_clear (t=%0t)", $time); end
      if (px_clear && px_fill) begin errors = errors + 1; $display("FAIL: px_clear and px_fill together (t=%0t)", $time); end
      if (o_pop > 9'd256)      begin errors = errors + 1; $display("FAIL: population above 256 (t=%0t)", $time); end
    end
  end

  integer g;
  initial begin
    repeat (8) @(posedge clk);
    rst = 1'b0;
    wait_frames(2);

    chk(o_pop == 9'd0,  "population not zero after reset");
    chk(o_gen == 16'd0, "generation not zero after reset");
    chk(!o_running,     "running after reset");

    // a clear-board start, then light the centre cell
    press_clear;
    chk(o_pop == 9'd0, "clear left live cells");
    press_toggle;
    chk(o_pop == 9'd1, "toggle did not create one live cell");

    // single step: a lone cell has 0 neighbours and dies, generation +1
    press_step;
    chk(o_pop == 9'd0,  "lone cell survived a step");
    chk(o_gen == 16'd1, "generation did not advance on the step");

    // build a horizontal 3-cell blinker centred on (8,8)
    press_clear;
    chk(o_gen == 16'd0, "clear did not reset the generation");
    press_toggle;                     // (8,8)
    press_left;  press_toggle;        // (7,8)
    press_right; press_right; press_toggle;  // (9,8)
    chk(o_pop == 9'd3, "blinker not 3 cells");

    // it oscillates with period 2: population stays 3 across steps
    press_step;
    chk(o_pop == 9'd3,  "blinker lost cells on step 1");
    chk(o_gen == 16'd1, "generation wrong after blinker step 1");
    press_step;
    chk(o_pop == 9'd3,  "blinker lost cells on step 2");
    chk(o_gen == 16'd2, "generation wrong after blinker step 2");

    // auto-run advances the generation; pausing freezes it
    speed = 2'd3;
    press_run;
    chk(o_running, "running flag not set by btn_run");
    wait_frames(4);
    chk(o_gen > 16'd2, "generation did not advance while running");
    chk(o_pop == 9'd3, "blinker broke while running");
    press_run;
    chk(!o_running, "running flag not cleared by btn_run");
    g = o_gen;
    wait_frames(4);
    chk(o_gen == g[15:0], "generation advanced while paused");

    // random seed: non-empty board, generation reset
    press_rand;
    repeat (20) @(posedge clk);       // 16-row fill plus margin
    chk(o_pop > 9'd0,   "random seed produced an empty board");
    chk(o_gen == 16'd0, "random seed did not reset the generation");

    press_clear;
    chk(o_pop == 9'd0, "final clear left live cells");

    // en low freezes the controls
    en = 1'b0;
    press_run;
    en = 1'b1;
    repeat (8) @(posedge clk);
    chk(!o_running, "run toggled while en was low");

    if (errors == 0) $display("PASS: tb_game_life16 (0 errors)");
    else             $display("FAIL: tb_game_life16 (%0d errors)", errors);
    $finish;
  end

  initial begin
    #2_000_000;
    $display("FAIL: tb_game_life16 global timeout");
    $finish;
  end

endmodule
