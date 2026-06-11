// ============================================================================
// game_rps_lite.v  --  family: games  --  rock-paper-scissors, no display
// ----------------------------------------------------------------------------
// SchemaGates game module.  Self-contained file: every submodule used is
// embedded below (duplication across files is intentional, see repo README).
// Top module name == filename == catalog name.
//
// LITE VARIANT (build-your-own-display):
//   Same game brain as game_rps.v, but there is NO pixel bus.  Every fact
//   about the game is a plain 1-bit (or small-bus) output, so you can wire
//   the module straight to lamps / LEDs / 7-segment decoders on the canvas
//   and design the front panel yourself:
//     o_p_rock / o_p_paper / o_p_scissors   your throw      (one-hot, 0 = none)
//     o_c_rock / o_c_paper / o_c_scissors   CPU's throw     (one-hot, 0 = none)
//     o_win / o_lose / o_draw               last result     (one-hot, 0 = idle)
//     o_score_p / o_score_c                 running scores  (binary, sat at 15)
//
// GAME:  Press btn_rock / btn_paper / btn_scissors to throw.  The CPU picks
//   by sampling a free-running mod-3 counter at the instant you press, so
//   its choice depends on your (humanly unpredictable) timing -- no LFSR
//   needed.  If several throw buttons are pressed on the same clock edge,
//   priority is rock > paper > scissors.  btn_new clears the table.
//
// VERIFIED WITH: tests/games/tb_game_rps_lite.v (self-checking).
// ----------------------------------------------------------------------------
// define clk          input  255.170.0
// define rst          input  255.0.0
// define en           input  0.200.255
// define btn_rock     input  0.255.128
// define btn_paper    input  0.255.128
// define btn_scissors input  0.255.128
// define btn_new      input  255.255.0
// define o_p_rock     output 0.255.255
// define o_p_paper    output 0.255.255
// define o_p_scissors output 0.255.255
// define o_c_rock     output 255.128.0
// define o_c_paper    output 255.128.0
// define o_c_scissors output 255.128.0
// define o_win        output 0.255.0
// define o_lose       output 255.64.64
// define o_draw       output 170.170.170
// define o_score_p    output 0.255.255
// define o_score_c    output 255.128.0
// ============================================================================

module game_rps_lite (
  input  wire       clk,
  input  wire       rst,          // synchronous, active high
  input  wire       en,           // global enable (freezes the game)
  input  wire       btn_rock,
  input  wire       btn_paper,
  input  wire       btn_scissors,
  input  wire       btn_new,
  output wire       o_p_rock,     // player threw rock      (one-hot...
  output wire       o_p_paper,    // player threw paper      ...all low =
  output wire       o_p_scissors, // player threw scissors   nothing yet)
  output wire       o_c_rock,     // CPU threw rock
  output wire       o_c_paper,    // CPU threw paper
  output wire       o_c_scissors, // CPU threw scissors
  output wire       o_win,        // player won the last round
  output wire       o_lose,       // CPU won the last round
  output wire       o_draw,       // last round was a draw
  output wire [3:0] o_score_p,    // player score, saturates at 15
  output wire [3:0] o_score_c     // CPU score, saturates at 15
);

  // -------------------------------------------------------------------------
  // encodings
  // -------------------------------------------------------------------------
  localparam [1:0] CH_ROCK = 2'd0;
  localparam [1:0] CH_PAPR = 2'd1;
  localparam [1:0] CH_SCIS = 2'd2;
  localparam [1:0] CH_NONE = 2'd3;

  localparam [1:0] R_IDLE  = 2'd0;
  localparam [1:0] R_DRAW  = 2'd1;
  localparam [1:0] R_WIN   = 2'd2;   // player won
  localparam [1:0] R_LOSE  = 2'd3;   // CPU won

  // -------------------------------------------------------------------------
  // button conditioning (sync + rising-edge pulse)
  // -------------------------------------------------------------------------
  wire p_rock, p_papr, p_scis, p_new;
  wire l_unused0, l_unused1, l_unused2, l_unused3;

  game_btn u_b_rock (.clk(clk), .rst(rst), .d(btn_rock),     .pulse(p_rock), .level(l_unused0));
  game_btn u_b_papr (.clk(clk), .rst(rst), .d(btn_paper),    .pulse(p_papr), .level(l_unused1));
  game_btn u_b_scis (.clk(clk), .rst(rst), .d(btn_scissors), .pulse(p_scis), .level(l_unused2));
  game_btn u_b_new  (.clk(clk), .rst(rst), .d(btn_new),      .pulse(p_new),  .level(l_unused3));

  wire       p_any = p_rock | p_papr | p_scis;
  wire [1:0] p_sel = p_rock ? CH_ROCK : (p_papr ? CH_PAPR : CH_SCIS);

  // -------------------------------------------------------------------------
  // CPU "brain": free-running mod-3 counter, sampled when the player throws.
  // The sample instant depends on human timing relative to the clock, which
  // is unpredictable -- a deliberately simple alternative to an LFSR.
  // -------------------------------------------------------------------------
  reg [1:0] cnt3;
  always @(posedge clk) begin
    if (rst) cnt3 <= 2'd0;
    else     cnt3 <= (cnt3 == CH_SCIS) ? 2'd0 : (cnt3 + 2'd1);
  end

  // does choice a beat choice b?  rock>scissors, paper>rock, scissors>paper
  function f_beats;
    input [1:0] a;
    input [1:0] b;
    begin
      f_beats = ((a == CH_ROCK) && (b == CH_SCIS)) ||
                ((a == CH_PAPR) && (b == CH_ROCK)) ||
                ((a == CH_SCIS) && (b == CH_PAPR));
    end
  endfunction

  // -------------------------------------------------------------------------
  // round state + scores (saturating at 15)
  // -------------------------------------------------------------------------
  reg [1:0] p_choice, c_choice, result;
  reg [3:0] score_p, score_c;

  always @(posedge clk) begin
    if (rst) begin
      p_choice <= CH_NONE;
      c_choice <= CH_NONE;
      result   <= R_IDLE;
      score_p  <= 4'd0;
      score_c  <= 4'd0;
    end else if (en) begin
      if (p_new) begin
        p_choice <= CH_NONE;
        c_choice <= CH_NONE;
        result   <= R_IDLE;
        score_p  <= 4'd0;
        score_c  <= 4'd0;
      end else if (p_any) begin
        p_choice <= p_sel;
        c_choice <= cnt3;
        if (p_sel == cnt3) begin
          result <= R_DRAW;
        end else if (f_beats(p_sel, cnt3)) begin
          result <= R_WIN;
          if (score_p != 4'hF) score_p <= score_p + 4'd1;
        end else begin
          result <= R_LOSE;
          if (score_c != 4'hF) score_c <= score_c + 4'd1;
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // one-hot output decode -- this replaces the whole raster/glyph stage of
  // game_rps.v.  All low means "nothing yet" (after rst or btn_new).
  // -------------------------------------------------------------------------
  assign o_p_rock     = (p_choice == CH_ROCK);
  assign o_p_paper    = (p_choice == CH_PAPR);
  assign o_p_scissors = (p_choice == CH_SCIS);

  assign o_c_rock     = (c_choice == CH_ROCK);
  assign o_c_paper    = (c_choice == CH_PAPR);
  assign o_c_scissors = (c_choice == CH_SCIS);

  assign o_draw = (result == R_DRAW);
  assign o_win  = (result == R_WIN);
  assign o_lose = (result == R_LOSE);

  assign o_score_p = score_p;
  assign o_score_c = score_c;

endmodule

// ============================================================================
// embedded helpers (shared across the games family by copy, not by include)
// ============================================================================

module game_sync2 (
  input  wire clk,
  input  wire d,
  output reg  q
);
  reg m;
  always @(posedge clk) begin
    m <= d;
    q <= m;
  end
endmodule

module game_btn (
  input  wire clk,
  input  wire rst,
  input  wire d,
  output wire pulse,
  output wire level
);
  wire s;
  reg  p;
  game_sync2 u_sync (.clk(clk), .d(d), .q(s));
  always @(posedge clk) begin
    if (rst) p <= 1'b0;
    else     p <= s;
  end
  assign pulse = s & ~p;
  assign level = s;
endmodule
