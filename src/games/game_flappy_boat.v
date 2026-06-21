// ============================================================================
// game_flappy_boat.v  --  family: games  --  one-button side-scroller, 64x32
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
// GAME:  A small boat (flag, sail, hull) must sail through gaps in an
//   endless stream of pillars, one pixel of scroll per frame.  btn_flap
//   gives the boat a hop; gravity does the rest (5.4 fixed-point vertical
//   position, signed 1/16-px velocity, terminal speed).  Touch a pillar or
//   the animated water line and it's over -- flap again (or btn_new) to
//   restart after a short pause.  Four pillars recycle around an 84-column
//   track with LFSR-randomised gaps, so the course never repeats.
//
// VERIFIED WITH: tests/games/tb_game_flappy_boat.v (self-checking).
// ----------------------------------------------------------------------------
// define clk       input  255.170.0
// define rst       input  255.0.0
// define en        input  0.200.255
// define btn_flap  input  0.255.128
// define btn_new   input  255.255.0
// define px_x      output 255.255.0
// define px_y      output 255.255.0
// define px_en     output 255.255.255
// define px_clear  output 128.128.255
// define px_fill   output 255.128.255
// define frame     output 170.170.170
// define o_score   output 0.255.255
// define o_dead    output 255.64.64
// define o_playing output 0.255.255
// ============================================================================

module game_flappy_boat (
  input  wire       clk,
  input  wire       rst,         // synchronous, active high
  input  wire       en,          // global enable (freezes game + raster)
  input  wire       btn_flap,
  input  wire       btn_new,
  output wire [5:0] px_x,
  output wire [4:0] px_y,
  output wire       px_en,
  output wire       px_clear,
  output wire       px_fill,
  output wire       frame,
  output wire [7:0] o_score,
  output wire       o_dead,
  output wire       o_playing
);

  // -------------------------------------------------------------------------
  // states / constants
  // -------------------------------------------------------------------------
  localparam [1:0] ST_READY = 2'd0;
  localparam [1:0] ST_PLAY  = 2'd1;
  localparam [1:0] ST_DEAD  = 2'd2;

  // 4x3 boat sprite, bit index = {ly[1:0], lx[1:0]}
  //   row 0: .X..   (flag)
  //   row 1: .XX.   (sail)
  //   row 2: XXXX   (hull)
  localparam [11:0] SPRITE = 12'b1111_0110_0010;

  localparam [5:0] V_GRAV = 6'd2;            // 2/16 px per frame^2
  localparam [5:0] V_FLAP = 6'b101110;       // -18 in two's complement
  localparam [5:0] V_TERM = 6'd20;           // terminal fall speed

  // -------------------------------------------------------------------------
  // button conditioning
  // -------------------------------------------------------------------------
  wire p_flap, p_new;
  wire l_u0, l_u1;

  game_btn u_b_flap (.clk(clk), .rst(rst), .d(btn_flap), .pulse(p_flap), .level(l_u0));
  game_btn u_b_new  (.clk(clk), .rst(rst), .d(btn_new),  .pulse(p_new),  .level(l_u1));

  wire [15:0] rnd;
  game_lfsr16 u_lfsr (.clk(clk), .rst(rst), .en(en), .q(rnd));

  // -------------------------------------------------------------------------
  // raster generator: 64x32 row-major sweep with a 1-cycle clear between
  // frames.  The world scrolls one pixel per frame.
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
      end else if (r_x == 6'd63) begin
        r_x <= 6'd0;
        if (r_y == 5'd31) begin
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

  wire tick = en && r_clear;

  // flap presses can land on any clock; latch them until the next frame tick
  reg flap_req;
  always @(posedge clk) begin
    if (rst)         flap_req <= 1'b0;
    else if (en) begin
      if (p_flap)    flap_req <= 1'b1;
      else if (tick) flap_req <= 1'b0;
    end
  end

  // -------------------------------------------------------------------------
  // game registers
  // -------------------------------------------------------------------------
  reg [8:0] posy;                // boat top, 5.4 fixed point
  reg [5:0] vel;                 // signed, 1/16 px per frame
  reg [1:0] gstate;
  reg [7:0] score;
  reg [6:0] dead_cnt;

  reg [6:0] ppx [0:3];           // pillar left edges, 0..84 (off-screen > 63)
  reg [4:0] pgy [0:3];           // gap top rows, 4..19 (gap is 12 rows tall)

  wire [4:0] by = posy[8:4];     // boat top row, integer pixels

  // -------------------------------------------------------------------------
  // per-pillar combinational taps (constant-index whole-word array reads)
  // -------------------------------------------------------------------------
  wire [6:0] w_px [0:3];
  wire [4:0] w_gy [0:3];
  wire [3:0] xov;                // pillar overlaps the boat columns 10..13
  wire [3:0] passed;             // pillar trailing edge just cleared the boat
  wire [3:0] pier;               // pillar covers the current raster pixel

  genvar gi;
  generate
    for (gi = 0; gi < 4; gi = gi + 1) begin : g_pil
      assign w_px[gi] = ppx[gi];
      assign w_gy[gi] = pgy[gi];
      assign xov[gi]    = (w_px[gi] <= 7'd13) && ((w_px[gi] + 7'd3) >= 7'd10);
      assign passed[gi] = ((w_px[gi] + 7'd3) == 7'd9);
      assign pier[gi]   = ({1'b0, r_x} >= w_px[gi]) &&
                          ({1'b0, r_x} <= (w_px[gi] + 7'd3)) &&
                          ((r_y < w_gy[gi]) || (r_y > (w_gy[gi] + 5'd11))) &&
                          (r_y < 5'd30);
    end
  endgenerate

  // boat vs pillar: outside the gap while column-overlapped
  wire [3:0] yhit;
  generate
    for (gi = 0; gi < 4; gi = gi + 1) begin : g_hit
      assign yhit[gi] = xov[gi] &&
                        ((by < w_gy[gi]) || ((by + 5'd1) > (w_gy[gi] + 5'd11)));
    end
  endgenerate

  wire crash_pier  = |yhit;
  wire crash_water = ((by + 5'd1) >= 5'd30);
  wire crash       = crash_pier || crash_water;

  // -------------------------------------------------------------------------
  // physics helpers
  // -------------------------------------------------------------------------
  wire [5:0] vel_g    = vel + V_GRAV;
  // signed compare against terminal speed: positive and above limit?
  wire       too_fast = !vel_g[5] && (vel_g > V_TERM);
  wire [5:0] vel_n    = too_fast ? V_TERM : vel_g;

  wire [9:0] posy_n10 = {1'b0, posy} + {{4{vel_n[5]}}, vel_n};
  wire [8:0] posy_n   = posy_n10[9] ? 9'd0 : posy_n10[8:0];   // ceiling clamp

  // -------------------------------------------------------------------------
  // main game process (one step per frame)
  // -------------------------------------------------------------------------
  integer j;
  always @(posedge clk) begin
    if (rst || (en && p_new) ||
        (en && tick && (gstate == ST_DEAD) && flap_req && (dead_cnt > 7'd60))) begin
      posy     <= 9'd256;        // y = 16.0
      vel      <= 6'd0;
      gstate   <= ST_READY;
      score    <= 8'd0;
      dead_cnt <= 7'd0;
      ppx[0]   <= 7'd39;  pgy[0] <= 5'd10;
      ppx[1]   <= 7'd60;  pgy[1] <= 5'd14;
      ppx[2]   <= 7'd81;  pgy[2] <= 5'd8;
      ppx[3]   <= 7'd102; pgy[3] <= 5'd16;
    end else if (en && tick) begin
      if (gstate == ST_READY) begin
        posy <= {(5'd16 + {4'd0, frame_cnt[4]}), 4'd0};
        if (flap_req) begin
          gstate <= ST_PLAY;
          vel    <= V_FLAP;
        end
      end else if (gstate == ST_PLAY) begin
        if (crash) begin
          gstate   <= ST_DEAD;
          dead_cnt <= 7'd0;
        end else begin
          // physics
          vel  <= flap_req ? V_FLAP : vel_n;
          posy <= posy_n;
          // world scroll + pillar recycling (one pillar at most wraps)
          for (j = 0; j < 4; j = j + 1) begin
            if (ppx[j] == 7'd0) begin
              ppx[j] <= 7'd83;
              pgy[j] <= 5'd4 + {1'b0, rnd[3:0]};
            end else begin
              ppx[j] <= ppx[j] - 7'd1;
            end
          end
          // scoring
          if ((|passed) && (score != 8'hFF)) score <= score + 8'd1;
        end
      end else begin // ST_DEAD
        if (dead_cnt != 7'h7F) dead_cnt <= dead_cnt + 7'd1;
      end
    end
  end

  // -------------------------------------------------------------------------
  // pixel function
  // -------------------------------------------------------------------------
  wire in_boat_x = (r_x >= 6'd10) && (r_x <= 6'd13);
  wire in_boat_y = (r_y >= by) && ({1'b0, r_y} <= ({1'b0, by} + 6'd2));
  wire [1:0] blx = r_x[1:0] - 2'd2;            // (r_x - 10) mod 4
  wire [1:0] bly = r_y[1:0] - by[1:0];         // 0..2 inside the sprite
  wire boatbit   = SPRITE[{bly, blx}];
  wire boatpx    = in_boat_x && in_boat_y && boatbit &&
                   !((gstate == ST_DEAD) && frame_cnt[2]);

  wire waterpx = (r_y == 5'd30) ||
                 ((r_y == 5'd31) && ((r_x[0] ^ frame_cnt[0]) == 1'b1));

  wire pix = boatpx | (|pier) | waterpx;

  // -------------------------------------------------------------------------
  // pixel bus + status outputs
  // -------------------------------------------------------------------------
  assign px_x     = r_x;
  assign px_y     = r_y;
  assign frame    = en & r_clear;
  assign px_clear = en & r_clear;
  assign px_fill  = 1'b0;
  assign px_en    = en & ~r_clear & pix;

  assign o_score   = score;
  assign o_dead    = (gstate == ST_DEAD);
  assign o_playing = (gstate == ST_PLAY);

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
