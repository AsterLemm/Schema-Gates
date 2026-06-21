// ============================================================================
// game_minesweeper.v  --  family: games  --  8x8 minesweeper, 32x32 px
// ----------------------------------------------------------------------------
// SchemaGates game module.  Self-contained file: every submodule used is
// embedded below (duplication across files is intentional, see repo README).
// Top module name == filename == catalog name.
// GENERATED FILE -- edit scripts/gen_game_minesweeper.py / mines_template.v.
//
// DISPLAY CONTRACT (games-family pixel bus, see docs/games.md):
//   Each frame: 1-cycle px_clear pulse (display blanks), then a row-major
//   raster sweep of the whole screen.  While sweeping, px_en=1 lights the
//   pixel at (px_x,px_y).  The display latches pixels between clears.
//   px_fill is a 1-cycle pulse that sets the whole screen (effects only).
//   frame pulses once per frame, on the clear/fill cycle.
//
// GAME:  8x8 board, 10 mines.  Each board cell is a 4x4 screen block with a
//   3x3 drawable core (row/column 3 of every block is grid spacing).  Move
//   the cursor (it wraps at the edges and inverts the cell it sits on),
//   btn_reveal opens a cell, btn_flag toggles a flag on a hidden cell.
//   The first reveal is always safe: mines are only placed after it, never
//   on the revealed cell.  Opening a 0-count cell flood-reveals its whole
//   region.  Revealed counts 1..8 are drawn as dice-style dot patterns;
//   hidden cells are solid blocks; flags are blocks with a hollow centre.
//   Revealing a mine ends the game and every mine is drawn as an X.
//   Revealing all 54 safe cells wins (the screen flashes).  btn_new
//   restarts at any time.
//
// VERIFIED WITH: tests/games/tb_game_minesweeper.v (self-checking).
// ----------------------------------------------------------------------------
// define clk        input  255.170.0
// define rst        input  255.0.0
// define en         input  0.200.255
// define btn_up     input  0.255.0
// define btn_down   input  0.255.0
// define btn_left   input  0.255.0
// define btn_right  input  0.255.0
// define btn_reveal input  0.255.128
// define btn_flag   input  0.255.128
// define btn_new    input  255.255.0
// define px_x       output 255.255.0
// define px_y       output 255.255.0
// define px_en      output 255.255.255
// define px_clear   output 128.128.255
// define px_fill    output 255.128.255
// define frame      output 170.170.170
// define o_flags    output 0.255.255
// define o_boom     output 255.64.64
// define o_win      output 0.255.255
// ============================================================================

module game_minesweeper (
  input  wire        clk,
  input  wire        rst,        // synchronous, active high
  input  wire        en,         // global enable (freezes game + raster)
  input  wire        btn_up,
  input  wire        btn_down,
  input  wire        btn_left,
  input  wire        btn_right,
  input  wire        btn_reveal,
  input  wire        btn_flag,
  input  wire        btn_new,
  output wire [4:0]  px_x,
  output wire [4:0]  px_y,
  output wire        px_en,
  output wire        px_clear,
  output wire        px_fill,
  output wire        frame,
  output wire [3:0]  o_flags,    // flags placed (display value, caps at 15)
  output wire        o_boom,
  output wire        o_win
);

  // -------------------------------------------------------------------------
  // game states
  // -------------------------------------------------------------------------
  localparam [2:0] ST_WAIT  = 3'd0;  // board empty, waiting for first reveal
  localparam [2:0] ST_SETUP = 3'd1;  // scattering 10 mines (first cell safe)
  localparam [2:0] ST_PLAY  = 3'd2;
  localparam [2:0] ST_FLOOD = 3'd3;  // flood-reveal pass over the board
  localparam [2:0] ST_BOOM  = 3'd4;
  localparam [2:0] ST_WIN   = 3'd5;

  // -------------------------------------------------------------------------
  // button conditioning (sync + rising-edge pulse)
  // -------------------------------------------------------------------------
  wire p_up, p_down, p_left, p_right, p_reveal, p_flag, p_new;
  wire l_unused0, l_unused1, l_unused2, l_unused3, l_unused4, l_unused5, l_unused6;

  game_btn u_b_up     (.clk(clk), .rst(rst), .d(btn_up),     .pulse(p_up),     .level(l_unused0));
  game_btn u_b_down   (.clk(clk), .rst(rst), .d(btn_down),   .pulse(p_down),   .level(l_unused1));
  game_btn u_b_left   (.clk(clk), .rst(rst), .d(btn_left),   .pulse(p_left),   .level(l_unused2));
  game_btn u_b_right  (.clk(clk), .rst(rst), .d(btn_right),  .pulse(p_right),  .level(l_unused3));
  game_btn u_b_reveal (.clk(clk), .rst(rst), .d(btn_reveal), .pulse(p_reveal), .level(l_unused4));
  game_btn u_b_flag   (.clk(clk), .rst(rst), .d(btn_flag),   .pulse(p_flag),   .level(l_unused5));
  game_btn u_b_new    (.clk(clk), .rst(rst), .d(btn_new),    .pulse(p_new),    .level(l_unused6));

  wire [15:0] rnd;
  game_lfsr16 u_lfsr (.clk(clk), .rst(rst), .en(en), .q(rnd));

  // -------------------------------------------------------------------------
  // raster generator: 32x32 row-major sweep with a 1-cycle clear between
  // frames.  frame_cnt drives blink effects.
  // -------------------------------------------------------------------------
  reg [4:0] r_x;
  reg [4:0] r_y;
  reg       r_clear;
  reg [7:0] frame_cnt;

  always @(posedge clk) begin
    if (rst) begin
      r_x       <= 5'd0;
      r_y       <= 5'd0;
      r_clear   <= 1'b1;
      frame_cnt <= 8'd0;
    end else if (en) begin
      if (r_clear) begin
        r_clear   <= 1'b0;
        r_x       <= 5'd0;
        r_y       <= 5'd0;
        frame_cnt <= frame_cnt + 8'd1;
      end else if (r_x == 5'd31) begin
        r_x <= 5'd0;
        if (r_y == 5'd31) begin
          r_y     <= 5'd0;
          r_clear <= 1'b1;
        end else begin
          r_y <= r_y + 5'd1;
        end
      end else begin
        r_x <= r_x + 5'd1;
      end
    end
  end

  // -------------------------------------------------------------------------
  // board state: one bit per cell, index = {cy[2:0], cx[2:0]}.
  // -------------------------------------------------------------------------
  reg [63:0] mines;
  reg [63:0] revealed;
  reg [63:0] flags;
  reg [2:0]  state;
  reg [2:0]  ccx, ccy;       // cursor cell
  reg [5:0]  safe;           // first revealed cell, kept mine-free
  reg [3:0]  mcount;         // mines placed so far during ST_SETUP
  reg [5:0]  fcell;          // flood scan position
  reg        fchanged;       // flood pass revealed something

  wire [5:0] cci = {ccy, ccx};

  // -------------------------------------------------------------------------
  // per-cell adjacent-mine counts (edge-aware, all indices compile-time).
  // cnt_flat[4c+3 : 4c] = number of mines in the 8 neighbours of cell c.
  // -------------------------------------------------------------------------
  wire [255:0] cnt_flat;

  genvar c;
  generate
    for (c = 0; c < 64; c = c + 1) begin : g_cnt
      wire n0, n1, n2, n3, n4, n5, n6, n7;
      if (((c & 7) != 0) && ((c >> 3) != 0)) assign n0 = mines[c - 9];
      else                                   assign n0 = 1'b0;
      if ((c >> 3) != 0)                     assign n1 = mines[c - 8];
      else                                   assign n1 = 1'b0;
      if (((c & 7) != 7) && ((c >> 3) != 0)) assign n2 = mines[c - 7];
      else                                   assign n2 = 1'b0;
      if ((c & 7) != 0)                      assign n3 = mines[c - 1];
      else                                   assign n3 = 1'b0;
      if ((c & 7) != 7)                      assign n4 = mines[c + 1];
      else                                   assign n4 = 1'b0;
      if (((c & 7) != 0) && ((c >> 3) != 7)) assign n5 = mines[c + 7];
      else                                   assign n5 = 1'b0;
      if ((c >> 3) != 7)                     assign n6 = mines[c + 8];
      else                                   assign n6 = 1'b0;
      if (((c & 7) != 7) && ((c >> 3) != 7)) assign n7 = mines[c + 9];
      else                                   assign n7 = 1'b0;
      assign cnt_flat[(c << 2) +: 4] =
          {3'b000, n0} + {3'b000, n1} + {3'b000, n2} + {3'b000, n3} +
          {3'b000, n4} + {3'b000, n5} + {3'b000, n6} + {3'b000, n7};
    end
  endgenerate

  // -------------------------------------------------------------------------
  // flood-reveal support: one-hot mask of the in-bounds neighbours of fcell.
  // A revealed 0-count cell pulls all unflagged neighbours into "revealed";
  // passes repeat until a full pass changes nothing.
  // -------------------------------------------------------------------------
  wire [2:0] fcx = fcell[2:0];
  wire [2:0] fcy = fcell[5:3];

  reg [63:0] nbm;
  always @* begin
    nbm = 64'd0;
    if (fcy != 3'd0)                  nbm = nbm | (64'd1 << (fcell - 6'd8));
    if (fcy != 3'd7)                  nbm = nbm | (64'd1 << (fcell + 6'd8));
    if (fcx != 3'd0)                  nbm = nbm | (64'd1 << (fcell - 6'd1));
    if (fcx != 3'd7)                  nbm = nbm | (64'd1 << (fcell + 6'd1));
    if ((fcy != 3'd0) && (fcx != 3'd0)) nbm = nbm | (64'd1 << (fcell - 6'd9));
    if ((fcy != 3'd0) && (fcx != 3'd7)) nbm = nbm | (64'd1 << (fcell - 6'd7));
    if ((fcy != 3'd7) && (fcx != 3'd0)) nbm = nbm | (64'd1 << (fcell + 6'd7));
    if ((fcy != 3'd7) && (fcx != 3'd7)) nbm = nbm | (64'd1 << (fcell + 6'd9));
  end

  wire [3:0]  fcnt   = cnt_flat[{fcell, 2'b00} +: 4];
  wire        expand = revealed[fcell] && !mines[fcell] && (fcnt == 4'd0);
  wire [63:0] nb_add = nbm & ~flags;
  wire [63:0] nb_new = nb_add & ~revealed;
  wire        fhit   = expand && (nb_new != 64'd0);

  // -------------------------------------------------------------------------
  // popcounts: revealed cells (win = 54) and flags (status output).
  // -------------------------------------------------------------------------
  integer pi;
  reg [6:0] revcnt;
  reg [6:0] flagcnt;
  always @* begin
    revcnt  = 7'd0;
    flagcnt = 7'd0;
    for (pi = 0; pi < 64; pi = pi + 1) begin
      revcnt  = revcnt  + {6'b000000, revealed[pi]};
      flagcnt = flagcnt + {6'b000000, flags[pi]};
    end
  end

  // -------------------------------------------------------------------------
  // main FSM
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst) begin
      mines    <= 64'd0;
      revealed <= 64'd0;
      flags    <= 64'd0;
      state    <= ST_WAIT;
      ccx      <= 3'd3;
      ccy      <= 3'd3;
      safe     <= 6'd0;
      mcount   <= 4'd0;
      fcell    <= 6'd0;
      fchanged <= 1'b0;
    end else if (en) begin
      if (p_new) begin
        mines    <= 64'd0;
        revealed <= 64'd0;
        flags    <= 64'd0;
        state    <= ST_WAIT;
        mcount   <= 4'd0;
      end else begin
        case (state)
          ST_WAIT: begin
            if (p_up)    ccy <= ccy - 3'd1;
            if (p_down)  ccy <= ccy + 3'd1;
            if (p_left)  ccx <= ccx - 3'd1;
            if (p_right) ccx <= ccx + 3'd1;
            if (p_flag)  flags <= flags ^ (64'd1 << cci);
            if (p_reveal && !flags[cci]) begin
              safe   <= cci;
              mcount <= 4'd0;
              state  <= ST_SETUP;
            end
          end

          ST_SETUP: begin
            // one LFSR draw per clock; duplicates and the safe cell are
            // skipped until all 10 mines have landed.
            if (mcount == 4'd10) begin
              revealed <= revealed | (64'd1 << safe);
              fcell    <= 6'd0;
              fchanged <= 1'b0;
              state    <= ST_FLOOD;
            end else if ((rnd[5:0] != safe) && !mines[rnd[5:0]]) begin
              mines  <= mines | (64'd1 << rnd[5:0]);
              mcount <= mcount + 4'd1;
            end
          end

          ST_PLAY: begin
            if (revcnt == 7'd54) begin
              state <= ST_WIN;
            end else begin
              if (p_up)    ccy <= ccy - 3'd1;
              if (p_down)  ccy <= ccy + 3'd1;
              if (p_left)  ccx <= ccx - 3'd1;
              if (p_right) ccx <= ccx + 3'd1;
              if (p_flag && !revealed[cci]) flags <= flags ^ (64'd1 << cci);
              if (p_reveal && !flags[cci] && !revealed[cci]) begin
                revealed <= revealed | (64'd1 << cci);
                if (mines[cci]) begin
                  state <= ST_BOOM;
                end else begin
                  fcell    <= 6'd0;
                  fchanged <= 1'b0;
                  state    <= ST_FLOOD;
                end
              end
            end
          end

          ST_FLOOD: begin
            // one cell per clock; a pass that changed anything is rerun.
            if (fhit) begin
              revealed <= revealed | nb_add;
              fchanged <= 1'b1;
            end
            if (fcell == 6'd63) begin
              if (fchanged || fhit) begin
                fchanged <= 1'b0;
                fcell    <= 6'd0;
              end else begin
                state <= ST_PLAY;
              end
            end else begin
              fcell <= fcell + 6'd1;
            end
          end

          ST_BOOM: begin
            // mines drawn as X in the raster; wait for btn_new.
          end

          ST_WIN: begin
            // screen flash via px_fill; wait for btn_new.
          end

          default: state <= ST_WAIT;
        endcase
      end
    end
  end

  // -------------------------------------------------------------------------
  // count glyphs: dice-style dot patterns on the 3x3 cell core.
  // bit index = 3*ly + lx, bit 0 = top-left dot.
  // -------------------------------------------------------------------------
  // BITF_LUT
  function [8:0] dots;
    input [3:0] n;
    begin
      case (n)
@@DOTS@@
      default: dots = 9'b000000000;
      endcase
    end
  endfunction

  // -------------------------------------------------------------------------
  // raster: cell content from board state.
  // -------------------------------------------------------------------------
  wire [2:0] gcx = r_x[4:2];
  wire [2:0] gcy = r_y[4:2];
  wire [1:0] lx  = r_x[1:0];
  wire [1:0] ly  = r_y[1:0];
  wire [5:0] gci = {gcy, gcx};

  wire grev  = revealed[gci];
  wire gmine = mines[gci];
  wire gflag = flags[gci];
  wire [3:0] gcnt = cnt_flat[{gci, 2'b00} +: 4];

  wire in3    = (lx != 2'd3) && (ly != 2'd3);
  wire center = (lx == 2'd1) && (ly == 2'd1);
  wire xglyph = in3 && ((lx == ly) || (({1'b0, lx} + {1'b0, ly}) == 3'd2));

  wire [8:0] dotw = dots(gcnt);
  wire [3:0] didx = {1'b0, ly, 1'b0} + {2'b00, ly} + {2'b00, lx};  // 3*ly + lx
  wire dotpx = in3 && dotw[didx];

  reg cellpx;
  always @* begin
    cellpx = 1'b0;
    if ((state == ST_BOOM) && gmine) cellpx = xglyph;
    else if (!grev && gflag)         cellpx = in3 && !center;
    else if (!grev)                  cellpx = in3;
    else if (gcnt != 4'd0)           cellpx = dotpx;
  end

  // cursor inverts its cell core while the board is interactive
  wire blink   = frame_cnt[2];
  wire curlive = (state == ST_WAIT) || (state == ST_PLAY);
  wire curhere = (gcx == ccx) && (gcy == ccy);

  wire pix = cellpx ^ (curlive && curhere && blink && in3);

  wire winflash = (state == ST_WIN) && frame_cnt[2];

  // -------------------------------------------------------------------------
  // pixel bus + status outputs
  // -------------------------------------------------------------------------
  assign px_x     = r_x;
  assign px_y     = r_y;
  assign frame    = en & r_clear;
  assign px_clear = en & r_clear & ~winflash;
  assign px_fill  = en & r_clear &  winflash;
  assign px_en    = en & ~r_clear & pix;

  assign o_flags  = (flagcnt > 7'd15) ? 4'hF : flagcnt[3:0];
  assign o_boom   = (state == ST_BOOM);
  assign o_win    = (state == ST_WIN);

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
// game_lfsr16 : free-running 16-bit Fibonacci LFSR (taps 16,15,13,4).
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
