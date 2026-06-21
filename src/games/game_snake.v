// ============================================================================
// game_snake.v  --  family: games  --  snake on a 16x16 walled field
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
// GAME:  Steer with the arrow buttons (180-degree reversals are ignored).
//   Eat the blinking food pip to grow; hitting a wall or yourself ends the
//   game (the snake blinks).  Fill all 64 cells to win (the screen strobes).
//   btn_new restarts.  speed[1:0]: 0 = slowest (moves every 8th frame) ..
//   3 = every frame.  The body lives in a 64-deep shift register; food is
//   placed by a background LFSR "hunt" that rejects occupied cells.
//
// VERIFIED WITH: tests/games/tb_game_snake.v (self-checking).
// ----------------------------------------------------------------------------
// define clk       input  255.170.0
// define rst       input  255.0.0
// define en        input  0.200.255
// define btn_up    input  0.255.0
// define btn_down  input  0.255.0
// define btn_left  input  0.255.0
// define btn_right input  0.255.0
// define btn_new   input  255.255.0
// define speed     input  0.200.255
// define px_x      output 255.255.0
// define px_y      output 255.255.0
// define px_en     output 255.255.255
// define px_clear  output 128.128.255
// define px_fill   output 255.128.255
// define frame     output 170.170.170
// define o_len     output 0.255.255
// define o_over    output 255.64.64
// define o_win     output 0.255.255
// ============================================================================

module game_snake (
  input  wire       clk,
  input  wire       rst,         // synchronous, active high
  input  wire       en,          // global enable (freezes game + raster)
  input  wire       btn_up,
  input  wire       btn_down,
  input  wire       btn_left,
  input  wire       btn_right,
  input  wire       btn_new,
  input  wire [1:0] speed,       // 0 = slowest .. 3 = every frame
  output wire [3:0] px_x,
  output wire [3:0] px_y,
  output wire       px_en,
  output wire       px_clear,
  output wire       px_fill,
  output wire       frame,
  output wire [6:0] o_len,       // body length, 3..64
  output wire       o_over,
  output wire       o_win
);

  // -------------------------------------------------------------------------
  // game states / direction encoding
  // -------------------------------------------------------------------------
  localparam [1:0] ST_PLAY = 2'd0;
  localparam [1:0] ST_OVER = 2'd1;
  localparam [1:0] ST_WIN  = 2'd2;

  localparam [1:0] D_UP    = 2'd0;
  localparam [1:0] D_RIGHT = 2'd1;
  localparam [1:0] D_DOWN  = 2'd2;
  localparam [1:0] D_LEFT  = 2'd3;

  // -------------------------------------------------------------------------
  // button conditioning (sync + rising-edge pulse) and speed sync
  // -------------------------------------------------------------------------
  wire p_up, p_down, p_left, p_right, p_new;
  wire l_u0, l_u1, l_u2, l_u3, l_u4;

  game_btn u_b_up   (.clk(clk), .rst(rst), .d(btn_up),    .pulse(p_up),    .level(l_u0));
  game_btn u_b_down (.clk(clk), .rst(rst), .d(btn_down),  .pulse(p_down),  .level(l_u1));
  game_btn u_b_left (.clk(clk), .rst(rst), .d(btn_left),  .pulse(p_left),  .level(l_u2));
  game_btn u_b_rght (.clk(clk), .rst(rst), .d(btn_right), .pulse(p_right), .level(l_u3));
  game_btn u_b_new  (.clk(clk), .rst(rst), .d(btn_new),   .pulse(p_new),   .level(l_u4));

  wire [1:0] s_speed;
  game_sync2 u_sp0 (.clk(clk), .d(speed[0]), .q(s_speed[0]));
  game_sync2 u_sp1 (.clk(clk), .d(speed[1]), .q(s_speed[1]));

  wire [15:0] rnd;
  game_lfsr16 u_lfsr (.clk(clk), .rst(rst), .en(en), .q(rnd));

  // -------------------------------------------------------------------------
  // raster generator: 16x16 row-major sweep with a 1-cycle clear between
  // frames.  frame_cnt drives blink effects and the movement tick.
  // -------------------------------------------------------------------------
  reg [3:0] r_x;
  reg [3:0] r_y;
  reg       r_clear;
  reg [7:0] frame_cnt;

  always @(posedge clk) begin
    if (rst) begin
      r_x       <= 4'd0;
      r_y       <= 4'd0;
      r_clear   <= 1'b1;
      frame_cnt <= 8'd0;
    end else if (en) begin
      if (r_clear) begin
        r_clear   <= 1'b0;
        r_x       <= 4'd0;
        r_y       <= 4'd0;
        frame_cnt <= frame_cnt + 8'd1;
      end else if (r_x == 4'd15) begin
        r_x <= 4'd0;
        if (r_y == 4'd15) begin
          r_y     <= 4'd0;
          r_clear <= 1'b1;
        end else begin
          r_y <= r_y + 4'd1;
        end
      end else begin
        r_x <= r_x + 4'd1;
      end
    end
  end

  reg [7:0] smask;
  always @* begin
    case (s_speed)
      2'd0:    smask = 8'h07;
      2'd1:    smask = 8'h03;
      2'd2:    smask = 8'h01;
      default: smask = 8'h00;
    endcase
  end

  // -------------------------------------------------------------------------
  // game registers.  body[0] is the head; cell packing is {y[3:0], x[3:0]}.
  // -------------------------------------------------------------------------
  reg [7:0] body [0:63];
  reg [6:0] len;
  reg [1:0] dir, pend;
  reg [1:0] gstate;
  reg [7:0] food;
  reg       food_valid;

  wire [7:0] head = body[0];

  wire tick = en && r_clear && ((frame_cnt & smask) == 8'd0) &&
              (gstate == ST_PLAY);

  // movement delta for the pending direction (8-bit two's complement)
  reg [7:0] delta;
  always @* begin
    case (pend)
      D_UP:    delta = 8'hF0;    // y - 1
      D_RIGHT: delta = 8'h01;    // x + 1
      D_DOWN:  delta = 8'h10;    // y + 1
      default: delta = 8'hFF;    // x - 1
    endcase
  end

  wire [7:0] head_next = head + delta;

  // wall check: about to step off the field?
  wire wall_hit = ((pend == D_UP)    && (head[7:4] == 4'd0))  ||
                  ((pend == D_DOWN)  && (head[7:4] == 4'd15)) ||
                  ((pend == D_LEFT)  && (head[3:0] == 4'd0))  ||
                  ((pend == D_RIGHT) && (head[3:0] == 4'd15));

  wire eating = food_valid && (head_next == food);

  // self collision: compare head_next against every live segment.  The tail
  // cell is excluded unless we are growing this tick (it will have moved).
  reg [6:0] lim;
  always @* begin
    lim = eating ? len : (len - 7'd1);
  end

  wire [63:0] col_hit;
  wire [63:0] occ_rnd;          // is the LFSR's candidate cell occupied?
  wire [63:0] seg_px;           // does the raster pixel hit a segment?

  genvar k;
  generate
    for (k = 0; k < 64; k = k + 1) begin : g_seg
      assign col_hit[k] = (lim > k)            && (body[k] == head_next);
      assign occ_rnd[k] = (len > k)            && (body[k] == rnd[7:0]);
      assign seg_px[k]  = (len > k)            && (body[k] == {r_y, r_x});
    end
  endgenerate

  wire self_hit = |col_hit;

  // -------------------------------------------------------------------------
  // main game process
  // -------------------------------------------------------------------------
  integer j;
  always @(posedge clk) begin
    if (rst || (en && p_new)) begin
      body[0]    <= 8'h88;       // head  (8,8)
      body[1]    <= 8'h87;       // (7,8)
      body[2]    <= 8'h86;       // (6,8)
      len        <= 7'd3;
      dir        <= D_RIGHT;
      pend       <= D_RIGHT;
      gstate     <= ST_PLAY;
      food_valid <= 1'b0;
    end else if (en) begin
      // queue a direction change; reversals are ignored
      if (p_up    && (dir != D_DOWN))  pend <= D_UP;
      if (p_down  && (dir != D_UP))    pend <= D_DOWN;
      if (p_left  && (dir != D_RIGHT)) pend <= D_LEFT;
      if (p_right && (dir != D_LEFT))  pend <= D_RIGHT;

      // background food hunt: take the first free LFSR cell
      if ((gstate == ST_PLAY) && !food_valid && !(|occ_rnd)) begin
        food       <= rnd[7:0];
        food_valid <= 1'b1;
      end

      if (tick) begin
        if (wall_hit || self_hit) begin
          gstate <= ST_OVER;
        end else begin
          dir <= pend;
          for (j = 63; j > 0; j = j - 1) begin
            body[j] <= body[j-1];
          end
          body[0] <= head_next;
          if (eating) begin
            len        <= len + 7'd1;
            food_valid <= 1'b0;
            if (len == 7'd63) gstate <= ST_WIN;   // about to become 64
          end
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // pixel function
  // -------------------------------------------------------------------------
  wire blink  = frame_cnt[3];
  wire snake  = (|seg_px) && !((gstate == ST_OVER) && blink);
  wire foodpx = food_valid && ({r_y, r_x} == food) && frame_cnt[1];
  wire pix    = snake | foodpx;

  wire winflash = (gstate == ST_WIN) && frame_cnt[2];

  // -------------------------------------------------------------------------
  // pixel bus + status outputs
  // -------------------------------------------------------------------------
  assign px_x     = r_x;
  assign px_y     = r_y;
  assign frame    = en & r_clear;
  assign px_clear = en & r_clear & ~winflash;
  assign px_fill  = en & r_clear &  winflash;
  assign px_en    = en & ~r_clear & pix;

  assign o_len  = len;
  assign o_over = (gstate == ST_OVER);
  assign o_win  = (gstate == ST_WIN);

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
