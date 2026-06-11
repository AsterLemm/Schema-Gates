// ============================================================================
// game_pong.v  --  family: games  --  two-paddle pong, 64x48 px, first to 7
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
// GAME:  Left paddle = P1 (btn_p1_up/dn), right paddle = P2 -- or tie
//   cpu_p2 high and the machine plays P2 by tracking the incoming ball.
//   The 2x2 ball picks up "spin": hitting a paddle near its ends deflects
//   the ball up/down, the middle returns it flat.  After each point the
//   ball blinks at centre court for 32 frames, then serves toward whoever
//   conceded.  First to 7 wins (winner's paddle blinks); btn_new restarts.
//
// VERIFIED WITH: tests/games/tb_game_pong.v (self-checking).
// ----------------------------------------------------------------------------
// define clk       input  255.170.0
// define rst       input  255.0.0
// define en        input  0.200.255
// define btn_p1_up input  0.255.0
// define btn_p1_dn input  0.255.0
// define btn_p2_up input  0.255.0
// define btn_p2_dn input  0.255.0
// define cpu_p2    input  0.200.255
// define btn_new   input  255.255.0
// define px_x      output 255.255.0
// define px_y      output 255.255.0
// define px_en     output 255.255.255
// define px_clear  output 128.128.255
// define px_fill   output 255.128.255
// define frame     output 170.170.170
// define o_s1      output 0.255.255
// define o_s2      output 0.255.255
// define o_over    output 255.64.64
// define o_winner  output 0.255.255
// ============================================================================

module game_pong (
  input  wire       clk,
  input  wire       rst,         // synchronous, active high
  input  wire       en,          // global enable (freezes game + raster)
  input  wire       btn_p1_up,
  input  wire       btn_p1_dn,
  input  wire       btn_p2_up,
  input  wire       btn_p2_dn,
  input  wire       cpu_p2,      // 1 = machine drives the right paddle
  input  wire       btn_new,
  output wire [5:0] px_x,
  output wire [5:0] px_y,
  output wire       px_en,
  output wire       px_clear,
  output wire       px_fill,
  output wire       frame,
  output wire [2:0] o_s1,
  output wire [2:0] o_s2,
  output wire       o_over,
  output wire       o_winner     // valid when o_over: 0 = P1 won, 1 = P2 won
);

  // -------------------------------------------------------------------------
  // states / encodings
  // -------------------------------------------------------------------------
  localparam [1:0] ST_SERVE = 2'd0;
  localparam [1:0] ST_PLAY  = 2'd1;
  localparam [1:0] ST_OVER  = 2'd2;

  localparam       VX_LEFT  = 1'b0;
  localparam       VX_RIGHT = 1'b1;
  localparam [1:0] VY_NEG   = 2'b11;   // -1
  localparam [1:0] VY_ZERO  = 2'b00;
  localparam [1:0] VY_POS   = 2'b01;   // +1

  // -------------------------------------------------------------------------
  // button conditioning: paddles use held levels, btn_new uses the pulse
  // -------------------------------------------------------------------------
  wire l_p1u, l_p1d, l_p2u, l_p2d, p_new;
  wire q_u0, q_u1, q_u2, q_u3, l_u4;

  game_btn u_b_p1u (.clk(clk), .rst(rst), .d(btn_p1_up), .pulse(q_u0), .level(l_p1u));
  game_btn u_b_p1d (.clk(clk), .rst(rst), .d(btn_p1_dn), .pulse(q_u1), .level(l_p1d));
  game_btn u_b_p2u (.clk(clk), .rst(rst), .d(btn_p2_up), .pulse(q_u2), .level(l_p2u));
  game_btn u_b_p2d (.clk(clk), .rst(rst), .d(btn_p2_dn), .pulse(q_u3), .level(l_p2d));
  game_btn u_b_new (.clk(clk), .rst(rst), .d(btn_new),   .pulse(p_new), .level(l_u4));

  wire s_cpu;
  game_sync2 u_scpu (.clk(clk), .d(cpu_p2), .q(s_cpu));

  wire [15:0] rnd;
  game_lfsr16 u_lfsr (.clk(clk), .rst(rst), .en(en), .q(rnd));

  // -------------------------------------------------------------------------
  // raster generator: 64x48 row-major sweep with a 1-cycle clear between
  // frames.  The game advances one step per frame.
  // -------------------------------------------------------------------------
  reg [5:0] r_x;
  reg [5:0] r_y;
  reg       r_clear;
  reg [7:0] frame_cnt;

  always @(posedge clk) begin
    if (rst) begin
      r_x       <= 6'd0;
      r_y       <= 6'd0;
      r_clear   <= 1'b1;
      frame_cnt <= 8'd0;
    end else if (en) begin
      if (r_clear) begin
        r_clear   <= 1'b0;
        r_x       <= 6'd0;
        r_y       <= 6'd0;
        frame_cnt <= frame_cnt + 8'd1;
      end else if (r_x == 6'd63) begin
        r_x <= 6'd0;
        if (r_y == 6'd47) begin
          r_y     <= 6'd0;
          r_clear <= 1'b1;
        end else begin
          r_y <= r_y + 6'd1;
        end
      end else begin
        r_x <= r_x + 6'd1;
      end
    end
  end

  wire tick = en && r_clear;

  // -------------------------------------------------------------------------
  // game registers
  // -------------------------------------------------------------------------
  reg [5:0] bx, by;              // ball top-left; ball is 2x2
  reg       bvx;
  reg [1:0] bvy;
  reg [5:0] p1y, p2y;            // paddle tops; paddles are 1x8
  reg [2:0] s1, s2;
  reg [1:0] gstate;
  reg [5:0] serve_cnt;
  reg       serve_dir;           // who receives the next serve
  reg       winner;

  // ball/paddle vertical overlap
  wire ov1 = ((by + 6'd1) >= p1y) && (by <= (p1y + 6'd7));
  wire ov2 = ((by + 6'd1) >= p2y) && (by <= (p2y + 6'd7));

  // paddle face contacts (ball moving toward that paddle)
  wire hit1 = (gstate == ST_PLAY) && (bvx == VX_LEFT)  && (bx == 6'd2)  && ov1;
  wire hit2 = (gstate == ST_PLAY) && (bvx == VX_RIGHT) && (bx == 6'd60) && ov2;

  // spin zone: where on the paddle did the ball land?  rel = 0..8
  wire [5:0] rel1 = (by + 6'd1) - p1y;
  wire [5:0] rel2 = (by + 6'd1) - p2y;

  reg [1:0] zone1, zone2;
  always @* begin
    if      (rel1 <= 6'd2) zone1 = VY_NEG;
    else if (rel1 >= 6'd6) zone1 = VY_POS;
    else                   zone1 = VY_ZERO;
    if      (rel2 <= 6'd2) zone2 = VY_NEG;
    else if (rel2 >= 6'd6) zone2 = VY_POS;
    else                   zone2 = VY_ZERO;
  end

  // wall bounce, then paddle spin overrides
  wire [1:0] bvy_wall = ((by == 6'd0)  && (bvy == VY_NEG)) ? VY_POS :
                        ((by == 6'd46) && (bvy == VY_POS)) ? VY_NEG : bvy;
  wire [1:0] bvy_n = hit1 ? zone1 : (hit2 ? zone2 : bvy_wall);
  wire       bvx_n = hit1 ? VX_RIGHT : (hit2 ? VX_LEFT : bvx);

  // vertical move with clamping at the rails
  wire [5:0] nby_raw = by + {{4{bvy_n[1]}}, bvy_n};
  wire [5:0] nby     = (nby_raw > 6'd46) ? (bvy_n[1] ? 6'd0 : 6'd46) : nby_raw;

  // a point is scored when the ball reaches a side wall
  wire pt_p2 = (bvx == VX_LEFT)  && (bx == 6'd0);    // P1 missed
  wire pt_p1 = (bvx == VX_RIGHT) && (bx == 6'd62);   // P2 missed

  // CPU tracking for the right paddle (only while the ball approaches)
  wire cpu_dn = s_cpu && (gstate == ST_PLAY) && (bvx == VX_RIGHT) &&
                ((by + 6'd1) > (p2y + 6'd4));
  wire cpu_up = s_cpu && (gstate == ST_PLAY) && (bvx == VX_RIGHT) &&
                ((by + 6'd1) < (p2y + 6'd3));

  wire mv1_up = l_p1u;
  wire mv1_dn = l_p1d;
  wire mv2_up = s_cpu ? cpu_up : l_p2u;
  wire mv2_dn = s_cpu ? cpu_dn : l_p2d;

  // -------------------------------------------------------------------------
  // main game process (one step per frame)
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst || (en && p_new)) begin
      bx        <= 6'd31;
      by        <= 6'd23;
      bvx       <= rnd[1];
      bvy       <= rnd[0] ? VY_POS : VY_NEG;
      p1y       <= 6'd20;
      p2y       <= 6'd20;
      s1        <= 3'd0;
      s2        <= 3'd0;
      gstate    <= ST_SERVE;
      serve_cnt <= 6'd0;
      serve_dir <= rnd[1];
      winner    <= 1'b0;
    end else if (en && tick) begin
      // paddles (active during serve and play)
      if (gstate != ST_OVER) begin
        if (mv1_up && (p1y != 6'd0))  p1y <= p1y - 6'd1;
        if (mv1_dn && (p1y != 6'd40)) p1y <= p1y + 6'd1;
        if (mv2_up && (p2y != 6'd0))  p2y <= p2y - 6'd1;
        if (mv2_dn && (p2y != 6'd40)) p2y <= p2y + 6'd1;
      end

      if (gstate == ST_SERVE) begin
        serve_cnt <= serve_cnt + 6'd1;
        if (serve_cnt == 6'd31) begin
          bvx    <= serve_dir;
          bvy    <= rnd[0] ? VY_POS : VY_NEG;
          gstate <= ST_PLAY;
        end
      end else if (gstate == ST_PLAY) begin
        if (pt_p1 || pt_p2) begin
          bx        <= 6'd31;
          by        <= 6'd23;
          serve_cnt <= 6'd0;
          serve_dir <= pt_p1 ? VX_RIGHT : VX_LEFT;  // serve toward the loser
          if (pt_p1) begin
            s1 <= s1 + 3'd1;
            if (s1 == 3'd6) begin gstate <= ST_OVER; winner <= 1'b0; end
            else            begin gstate <= ST_SERVE;                end
          end else begin
            s2 <= s2 + 3'd1;
            if (s2 == 3'd6) begin gstate <= ST_OVER; winner <= 1'b1; end
            else            begin gstate <= ST_SERVE;                end
          end
        end else begin
          bvx <= bvx_n;
          bvy <= bvy_n;
          bx  <= bvx_n ? (bx + 6'd1) : (bx - 6'd1);
          by  <= nby;
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // pixel function
  // -------------------------------------------------------------------------
  wire blink = frame_cnt[3];

  wire pad1 = (r_x == 6'd1)  && (r_y >= p1y) && (r_y <= (p1y + 6'd7));
  wire pad2 = (r_x == 6'd62) && (r_y >= p2y) && (r_y <= (p2y + 6'd7));
  wire pad1v = pad1 && ((gstate != ST_OVER) || (winner != 1'b0) || blink);
  wire pad2v = pad2 && ((gstate != ST_OVER) || (winner != 1'b1) || blink);

  wire ballbox = (r_x >= bx) && (r_x <= (bx + 6'd1)) &&
                 (r_y >= by) && (r_y <= (by + 6'd1));
  wire ballv = ballbox && ((gstate == ST_PLAY) ||
                           ((gstate == ST_SERVE) && frame_cnt[2]));

  wire net = (r_x == 6'd32) && (r_y[1] == 1'b0);

  // score pips on the top row (every other pixel)
  wire [5:0] pidx1 = r_x - 6'd2;
  wire [5:0] pidx2 = r_x - 6'd48;
  wire pip1 = (r_y == 6'd0) && !r_x[0] && (r_x >= 6'd2)  && (r_x <= 6'd14) &&
              ({1'b0, pidx1[3:1]} < {1'b0, s1});
  wire pip2 = (r_y == 6'd0) && !r_x[0] && (r_x >= 6'd48) && (r_x <= 6'd60) &&
              ({1'b0, pidx2[3:1]} < {1'b0, s2});

  wire pix = pad1v | pad2v | ballv | net | pip1 | pip2;

  // -------------------------------------------------------------------------
  // pixel bus + status outputs
  // -------------------------------------------------------------------------
  assign px_x     = r_x;
  assign px_y     = r_y;
  assign frame    = en & r_clear;
  assign px_clear = en & r_clear;
  assign px_fill  = 1'b0;
  assign px_en    = en & ~r_clear & pix;

  assign o_s1     = s1;
  assign o_s2     = s2;
  assign o_over   = (gstate == ST_OVER);
  assign o_winner = winner;

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

// ----------------------------------------------------------------------------
// game_lfsr16 : free-running 16-bit maximal LFSR (taps 16,15,13,4).
// ----------------------------------------------------------------------------
module game_lfsr16 (
  input  wire        clk,
  input  wire        rst,
  input  wire        en,
  output reg  [15:0] q
);
  always @(posedge clk) begin
    if (rst)     q <= 16'hACE1;
    else if (en) q <= {q[14:0], q[15] ^ q[14] ^ q[12] ^ q[3]};
  end
endmodule
