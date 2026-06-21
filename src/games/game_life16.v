// ============================================================================
// game_life16.v  --  family: games  --  Conway's Game of Life, 16x16 torus
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
// GAME:  A 16x16 wraparound (torus) Life universe.  The whole next
//   generation is computed in parallel -- 256 cells x 8-neighbour adders --
//   and committed in a single clock on the frame boundary, so this file is
//   also a nice stress test for the synthesizer's adder farms.
//   Controls: btn_run toggles auto-evolve (speed[1:0]: 0 slowest .. 3 every
//   frame), btn_step single-steps while paused, btn_rand reseeds from an
//   LFSR (one row per clock, 16 clocks), btn_clear wipes the board, the
//   arrow buttons move the cursor (blinking XOR mark, visible while paused)
//   and btn_toggle flips the cell under it.
//
// VERIFIED WITH: tests/games/tb_game_life16.v (self-checking blinker test).
// ----------------------------------------------------------------------------
// define clk        input  255.170.0
// define rst        input  255.0.0
// define en         input  0.200.255
// define btn_run    input  0.255.128
// define btn_step   input  0.255.128
// define btn_rand   input  0.255.128
// define btn_clear  input  0.255.128
// define btn_toggle input  0.255.128
// define btn_up     input  0.255.0
// define btn_down   input  0.255.0
// define btn_left   input  0.255.0
// define btn_right  input  0.255.0
// define speed      input  0.200.255
// define px_x       output 255.255.0
// define px_y       output 255.255.0
// define px_en      output 255.255.255
// define px_clear   output 128.128.255
// define px_fill    output 255.128.255
// define frame      output 170.170.170
// define o_pop      output 0.255.255
// define o_gen      output 0.255.255
// define o_running  output 0.255.255
// ============================================================================

module game_life16 (
  input  wire        clk,
  input  wire        rst,        // synchronous, active high
  input  wire        en,         // global enable (freezes game + raster)
  input  wire        btn_run,
  input  wire        btn_step,
  input  wire        btn_rand,
  input  wire        btn_clear,
  input  wire        btn_toggle,
  input  wire        btn_up,
  input  wire        btn_down,
  input  wire        btn_left,
  input  wire        btn_right,
  input  wire [1:0]  speed,      // 0 = slowest (every 8th frame) .. 3 = every frame
  output wire [3:0]  px_x,
  output wire [3:0]  px_y,
  output wire        px_en,
  output wire        px_clear,
  output wire        px_fill,
  output wire        frame,
  output wire [8:0]  o_pop,      // live-cell count, 0..256
  output wire [15:0] o_gen,      // generation counter
  output wire        o_running
);

  // -------------------------------------------------------------------------
  // button conditioning (sync + rising-edge pulse) and speed sync
  // -------------------------------------------------------------------------
  wire p_run, p_step, p_rnd, p_clr, p_tgl, p_up, p_down, p_left, p_right;
  wire l_u0, l_u1, l_u2, l_u3, l_u4, l_u5, l_u6, l_u7, l_u8;

  game_btn u_b_run  (.clk(clk), .rst(rst), .d(btn_run),    .pulse(p_run),   .level(l_u0));
  game_btn u_b_step (.clk(clk), .rst(rst), .d(btn_step),   .pulse(p_step),  .level(l_u1));
  game_btn u_b_rnd  (.clk(clk), .rst(rst), .d(btn_rand),   .pulse(p_rnd),   .level(l_u2));
  game_btn u_b_clr  (.clk(clk), .rst(rst), .d(btn_clear),  .pulse(p_clr),   .level(l_u3));
  game_btn u_b_tgl  (.clk(clk), .rst(rst), .d(btn_toggle), .pulse(p_tgl),   .level(l_u4));
  game_btn u_b_up   (.clk(clk), .rst(rst), .d(btn_up),     .pulse(p_up),    .level(l_u5));
  game_btn u_b_down (.clk(clk), .rst(rst), .d(btn_down),   .pulse(p_down),  .level(l_u6));
  game_btn u_b_left (.clk(clk), .rst(rst), .d(btn_left),   .pulse(p_left),  .level(l_u7));
  game_btn u_b_rght (.clk(clk), .rst(rst), .d(btn_right),  .pulse(p_right), .level(l_u8));

  wire [1:0] s_speed;
  game_sync2 u_sp0 (.clk(clk), .d(speed[0]), .q(s_speed[0]));
  game_sync2 u_sp1 (.clk(clk), .d(speed[1]), .q(s_speed[1]));

  // -------------------------------------------------------------------------
  // random source for btn_rand reseeding
  // -------------------------------------------------------------------------
  wire [15:0] rnd;
  game_lfsr16 u_lfsr (.clk(clk), .rst(rst), .en(en), .q(rnd));

  // -------------------------------------------------------------------------
  // raster generator: 16x16 row-major sweep with a 1-cycle clear between
  // frames.  frame_cnt drives blink effects and the evolution tick.
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
      2'd0:    smask = 8'h07;     // every 8th frame
      2'd1:    smask = 8'h03;     // every 4th
      2'd2:    smask = 8'h01;     // every 2nd
      default: smask = 8'h00;     // every frame
    endcase
  end

  wire tick = en && r_clear && ((frame_cnt & smask) == 8'd0);

  // -------------------------------------------------------------------------
  // the universe: flat 256-bit vector, cell (x,y) at bit {y,x}.
  // Next generation computed fully in parallel by the generate farm below.
  // -------------------------------------------------------------------------
  reg  [255:0] grid;
  wire [255:0] nxt;

  genvar gx, gy;
  generate
    for (gy = 0; gy < 16; gy = gy + 1) begin : g_row
      for (gx = 0; gx < 16; gx = gx + 1) begin : g_col
        // 8-neighbour sum with constant (elaboration-time) torus indices
        wire [3:0] nsum =
          {3'b000, grid[((((gy+15)&15))<<4) | ((gx+15)&15)]} +
          {3'b000, grid[((((gy+15)&15))<<4) |  (gx       )]} +
          {3'b000, grid[((((gy+15)&15))<<4) | ((gx+ 1)&15)]} +
          {3'b000, grid[(( (gy       ))<<4) | ((gx+15)&15)]} +
          {3'b000, grid[(( (gy       ))<<4) | ((gx+ 1)&15)]} +
          {3'b000, grid[((((gy+ 1)&15))<<4) | ((gx+15)&15)]} +
          {3'b000, grid[((((gy+ 1)&15))<<4) |  (gx       )]} +
          {3'b000, grid[((((gy+ 1)&15))<<4) | ((gx+ 1)&15)]};
        // B3/S23
        assign nxt[(gy<<4) | gx] = (nsum == 4'd3) |
                                   (grid[(gy<<4) | gx] & (nsum == 4'd2));
      end
    end
  endgenerate

  // -------------------------------------------------------------------------
  // cursor
  // -------------------------------------------------------------------------
  reg [3:0] cx, cy;
  always @(posedge clk) begin
    if (rst) begin
      cx <= 4'd8;
      cy <= 4'd8;
    end else if (en) begin
      if (p_left)  cx <= cx - 4'd1;    // 4-bit wrap == torus wrap
      if (p_right) cx <= cx + 4'd1;
      if (p_up)    cy <= cy - 4'd1;
      if (p_down)  cy <= cy + 4'd1;
    end
  end

  // -------------------------------------------------------------------------
  // grid control FSM: idle (evolve / edit) or 16-clock random refill
  // -------------------------------------------------------------------------
  localparam M_IDLE = 1'b0;
  localparam M_RND  = 1'b1;

  reg         mstate;
  reg  [3:0]  rrow;
  reg         running;
  reg  [15:0] gen_cnt;

  always @(posedge clk) begin
    if (rst) begin
      grid    <= 256'd0;
      mstate  <= M_IDLE;
      rrow    <= 4'd0;
      running <= 1'b0;
      gen_cnt <= 16'd0;
    end else if (en) begin
      if (p_run) running <= ~running;

      if (mstate == M_RND) begin
        grid[{rrow, 4'b0000} +: 16] <= rnd;   // one fresh LFSR row per clock
        rrow <= rrow + 4'd1;
        if (rrow == 4'd15) mstate <= M_IDLE;
      end else begin
        if (p_rnd) begin
          mstate  <= M_RND;
          rrow    <= 4'd0;
          gen_cnt <= 16'd0;
        end else if (p_clr) begin
          grid    <= 256'd0;
          gen_cnt <= 16'd0;
        end else if (p_tgl) begin
          grid[{cy, cx}] <= ~grid[{cy, cx}];
        end else if ((tick && running) || (p_step && !running)) begin
          grid    <= nxt;
          gen_cnt <= gen_cnt + 16'd1;
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // population count (behavioural ripple of 256 single-bit adds)
  // -------------------------------------------------------------------------
  reg [8:0] pop;
  integer i;
  always @* begin
    pop = 9'd0;
    for (i = 0; i < 256; i = i + 1) begin
      pop = pop + {8'b00000000, grid[i]};
    end
  end

  // -------------------------------------------------------------------------
  // pixel function: live cell, XOR-blinked by the cursor while paused
  // -------------------------------------------------------------------------
  wire alive   = grid[{r_y, r_x}];
  wire curhere = (r_x == cx) && (r_y == cy);
  wire blink   = frame_cnt[2];
  wire pix     = alive ^ (curhere && !running && blink);

  // -------------------------------------------------------------------------
  // pixel bus + status outputs
  // -------------------------------------------------------------------------
  assign px_x     = r_x;
  assign px_y     = r_y;
  assign frame    = en & r_clear;
  assign px_clear = en & r_clear;
  assign px_fill  = 1'b0;
  assign px_en    = en & ~r_clear & pix;

  assign o_pop     = pop;
  assign o_gen     = gen_cnt;
  assign o_running = running;

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
