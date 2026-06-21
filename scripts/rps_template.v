// ============================================================================
// game_rps.v  --  family: games  --  rock-paper-scissors vs CPU, 40x24 px
// ----------------------------------------------------------------------------
// SchemaGates game module.  Self-contained file: every submodule used is
// embedded below (duplication across files is intentional, see repo README).
// Top module name == filename == catalog name.
//
// DISPLAY CONTRACT (games-family pixel bus, see docs/games.md):
//   Each frame: 1-cycle px_clear pulse (display blanks), then a row-major
//   raster sweep of the whole screen.  While sweeping, px_en=1 lights the
//   pixel at (px_x,px_y).  The display latches pixels between clears.
//   px_fill is a 1-cycle pulse that sets the whole screen (effects only).
//   frame pulses once per frame, on the clear/fill cycle.
//
// GAME:  Press btn_rock / btn_paper / btn_scissors to throw.  The CPU picks
//   by sampling a free-running mod-3 counter at the instant you press, so
//   its choice depends on your (humanly unpredictable) timing -- no LFSR
//   needed.  Left glyph = you, right glyph = CPU, the loser's glyph blinks.
//   Score pips along the top (max 8 shown, counters saturate at 15).
//   btn_new clears the scores.  Layout: 40x24, two 16x16 glyph boxes.
//
// VERIFIED WITH: tests/games/tb_game_rps.v (self-checking).
// ----------------------------------------------------------------------------
// define clk          input  255.170.0
// define rst          input  255.0.0
// define en           input  0.200.255
// define btn_rock     input  0.255.128
// define btn_paper    input  0.255.128
// define btn_scissors input  0.255.128
// define btn_new      input  255.255.0
// define px_x         output 255.255.0
// define px_y         output 255.255.0
// define px_en        output 255.255.255
// define px_clear     output 128.128.255
// define px_fill      output 255.128.255
// define frame        output 170.170.170
// define o_player     output 0.255.255
// define o_cpu        output 0.255.255
// define o_result     output 0.255.255
// define o_score_p    output 0.255.255
// define o_score_c    output 0.255.255
// ============================================================================

module game_rps (
  input  wire       clk,
  input  wire       rst,         // synchronous, active high
  input  wire       en,          // global enable (freezes game + raster)
  input  wire       btn_rock,
  input  wire       btn_paper,
  input  wire       btn_scissors,
  input  wire       btn_new,
  output wire [5:0] px_x,
  output wire [4:0] px_y,
  output wire       px_en,
  output wire       px_clear,
  output wire       px_fill,
  output wire       frame,
  output wire [1:0] o_player,    // 0 rock, 1 paper, 2 scissors, 3 none yet
  output wire [1:0] o_cpu,       // 0 rock, 1 paper, 2 scissors, 3 none yet
  output wire [1:0] o_result,    // 0 idle, 1 draw, 2 player won, 3 CPU won
  output wire [3:0] o_score_p,
  output wire [3:0] o_score_c
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
  // raster generator: 40x24 row-major sweep with a 1-cycle clear between
  // frames.  frame_cnt drives all blink effects.
  // -------------------------------------------------------------------------
  reg [5:0] r_x;
  reg [4:0] r_y;
  reg       r_clear;
  reg [7:0] frame_cnt;

  always @(posedge clk) begin
    if (rst) begin
      r_x       <= 6'd0;
      r_y       <= 5'd0;
      r_clear   <= 1'b1;
      frame_cnt <= 8'd0;
    end else if (en) begin
      if (r_clear) begin
        r_clear   <= 1'b0;
        r_x       <= 6'd0;
        r_y       <= 5'd0;
        frame_cnt <= frame_cnt + 8'd1;
      end else if (r_x == 6'd39) begin
        r_x <= 6'd0;
        if (r_y == 5'd23) begin
          r_y     <= 5'd0;
          r_clear <= 1'b1;
        end else begin
          r_y <= r_y + 5'd1;
        end
      end else begin
        r_x <= r_x + 6'd1;
      end
    end
  end

  // -------------------------------------------------------------------------
  // glyph artwork: four 16x16 bitmaps (rock / paper / scissors / unknown).
  // Index = {glyph[1:0], row[3:0]}; bit i of the row = pixel at local x = i.
  // Generated by scripts/gen_game_rps.py -- edit the ASCII art there.
  // -------------------------------------------------------------------------
  // BITF_LUT
  function [15:0] glyph_row;
    input [5:0] gidx;
    begin
      case (gidx)
@@LUT@@
        default: glyph_row = 16'h0000;
      endcase
    end
  endfunction

  // -------------------------------------------------------------------------
  // pixel function (combinational on the raster position)
  // -------------------------------------------------------------------------
  wire blink = frame_cnt[3];

  // glyph boxes: player x 2..17, CPU x 22..37, both y 5..20
  wire in_py  = (r_y >= 5'd5)  && (r_y <= 5'd20);
  wire in_pbx = (r_x >= 6'd2)  && (r_x <= 6'd17) && in_py;
  wire in_cbx = (r_x >= 6'd22) && (r_x <= 6'd37) && in_py;

  wire [3:0] gy  = r_y - 5'd5;          // 0..15 inside either box
  wire [3:0] pgx = r_x - 6'd2;          // 0..15 inside player box
  wire [3:0] cgx = r_x - 6'd22;         // 0..15 inside CPU box

  wire [1:0] pglyph = (result == R_IDLE) ? CH_NONE : p_choice;
  wire [1:0] cglyph = (result == R_IDLE) ? CH_NONE : c_choice;

  wire [15:0] prow = glyph_row({pglyph, gy});
  wire [15:0] crow = glyph_row({cglyph, gy});

  wire p_hide = (result == R_LOSE) && blink;   // loser blinks
  wire c_hide = (result == R_WIN)  && blink;

  wire g_p = in_pbx && prow[pgx] && !p_hide;
  wire g_c = in_cbx && crow[cgx] && !c_hide;

  // dashed centre divider, x = 19..20
  wire divider = ((r_x == 6'd19) || (r_x == 6'd20)) && (r_y[1] == 1'b0);

  // score pips along y = 2 (every other pixel, up to 8 per side)
  wire [3:0] disp_p = (score_p > 4'd8) ? 4'd8 : score_p;
  wire [3:0] disp_c = (score_c > 4'd8) ? 4'd8 : score_c;
  wire [5:0] ppidx  = r_x - 6'd2;       // /2 below via bit slice
  wire [5:0] cpidx  = r_x - 6'd22;
  wire pip_p = (r_y == 5'd2) && !r_x[0] && (r_x >= 6'd2)  && (r_x <= 6'd16) &&
               ({1'b0, ppidx[4:1]} < {1'b0, disp_p});
  wire pip_c = (r_y == 5'd2) && !r_x[0] && (r_x >= 6'd22) && (r_x <= 6'd36) &&
               ({1'b0, cpidx[4:1]} < {1'b0, disp_c});

  wire pix = g_p | g_c | divider | pip_p | pip_c;

  // -------------------------------------------------------------------------
  // pixel bus + status outputs
  // -------------------------------------------------------------------------
  assign px_x     = r_x;
  assign px_y     = r_y;
  assign frame    = en & r_clear;
  assign px_clear = en & r_clear;
  assign px_fill  = 1'b0;
  assign px_en    = en & ~r_clear & pix;

  assign o_player  = p_choice;
  assign o_cpu     = c_choice;
  assign o_result  = result;
  assign o_score_p = score_p;
  assign o_score_c = score_c;

endmodule

// ----------------------------------------------------------------------------
// game_sync2 : 2-flop input synchroniser (games-family helper).
// Embedded copy -- every SchemaGates file is self-contained by convention.
// ----------------------------------------------------------------------------
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

// ----------------------------------------------------------------------------
// game_btn : synchronised push-button -> 1-clk rising-edge pulse + held level.
// ----------------------------------------------------------------------------
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
