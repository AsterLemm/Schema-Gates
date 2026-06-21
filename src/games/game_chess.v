// ============================================================================
// game_chess.v  --  family: games  --  two-player chess (lite rules), 64x64 px
// ----------------------------------------------------------------------------
// SchemaGates game module.  Self-contained file: every submodule used is
// embedded below (duplication across files is intentional, see repo README).
// Top module name == filename == catalog name.
// GENERATED FILE -- edit scripts/gen_game_chess.py / chess_template.v.
//
// DISPLAY CONTRACT (games-family pixel bus, see docs/games.md):
//   Each frame: 1-cycle px_clear pulse (display blanks), then a row-major
//   raster sweep of the whole screen.  While sweeping, px_en=1 lights the
//   pixel at (px_x,px_y).  The display latches pixels between clears.
//   px_fill is a 1-cycle pulse that sets the whole screen (effects only).
//   frame pulses once per frame, on the clear/fill cycle.
//
// GAME:  Two-player chess on an 8x8 board of 8x8-pixel cells (white pieces
//   are drawn as outlines and start at the bottom, black pieces are solid
//   and start at the top; dark squares carry a sparse diagonal weave).
//   Both players share one cursor (blinking cell ring).  btn_sel on one of
//   your pieces selects it (solid ring); btn_sel on a destination moves if
//   the move is legal, on the selected piece deselects, on another of your
//   pieces reselects.  Illegal destinations are simply ignored.
//   LITE RULES: piece movement, blocking and captures are enforced and
//   pawns auto-promote to queens, but there is no check/checkmate logic,
//   no castling and no en passant -- you win by actually capturing the
//   king, after which the winner's pieces blink.  btn_new restarts.
//
// BOARD ENCODING:  sq[{y,x}] = {colour, type[2:0]}; colour 0 = white,
//   1 = black; type 0 empty, 1 pawn, 2 knight, 3 bishop, 4 rook,
//   5 queen, 6 king.  White moves toward y = 0.
//
// VERIFIED WITH: tests/games/tb_game_chess.v (self-checking).
// ----------------------------------------------------------------------------
// define clk       input  255.170.0
// define rst       input  255.0.0
// define en        input  0.200.255
// define btn_up    input  0.255.0
// define btn_down  input  0.255.0
// define btn_left  input  0.255.0
// define btn_right input  0.255.0
// define btn_sel   input  0.255.128
// define btn_new   input  255.255.0
// define px_x      output 255.255.0
// define px_y      output 255.255.0
// define px_en     output 255.255.255
// define px_clear  output 128.128.255
// define px_fill   output 255.128.255
// define frame     output 170.170.170
// define o_turn    output 0.255.255
// define o_over    output 255.64.64
// define o_winner  output 0.255.255
// define o_sel     output 0.255.255
// define o_src     output 0.255.255
// define o_cursor  output 0.255.255
// define o_piece   output 0.255.255
// ============================================================================

module game_chess (
  input  wire        clk,
  input  wire        rst,        // synchronous, active high
  input  wire        en,         // global enable (freezes game + raster)
  input  wire        btn_up,
  input  wire        btn_down,
  input  wire        btn_left,
  input  wire        btn_right,
  input  wire        btn_sel,
  input  wire        btn_new,
  output wire [5:0]  px_x,
  output wire [5:0]  px_y,
  output wire        px_en,
  output wire        px_clear,
  output wire        px_fill,
  output wire        frame,
  output wire        o_turn,     // 0 = white to move, 1 = black to move
  output wire        o_over,
  output wire        o_winner,   // valid when o_over: 0 = white, 1 = black
  output wire        o_sel,      // a source square is selected
  output wire [5:0]  o_src,      // selected square {y,x}
  output wire [5:0]  o_cursor,   // cursor square {y,x}
  output wire [3:0]  o_piece     // piece under the cursor {colour, type}
);

  // -------------------------------------------------------------------------
  // button conditioning (sync + rising-edge pulse)
  // -------------------------------------------------------------------------
  wire p_up, p_down, p_left, p_right, p_sel, p_new;
  wire l_unused0, l_unused1, l_unused2, l_unused3, l_unused4, l_unused5;

  game_btn u_b_up    (.clk(clk), .rst(rst), .d(btn_up),    .pulse(p_up),    .level(l_unused0));
  game_btn u_b_down  (.clk(clk), .rst(rst), .d(btn_down),  .pulse(p_down),  .level(l_unused1));
  game_btn u_b_left  (.clk(clk), .rst(rst), .d(btn_left),  .pulse(p_left),  .level(l_unused2));
  game_btn u_b_right (.clk(clk), .rst(rst), .d(btn_right), .pulse(p_right), .level(l_unused3));
  game_btn u_b_sel   (.clk(clk), .rst(rst), .d(btn_sel),   .pulse(p_sel),   .level(l_unused4));
  game_btn u_b_new   (.clk(clk), .rst(rst), .d(btn_new),   .pulse(p_new),   .level(l_unused5));

  // -------------------------------------------------------------------------
  // raster generator: 64x64 row-major sweep with a 1-cycle clear between
  // frames.  frame_cnt drives blink effects.
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
        if (r_y == 6'd63) begin
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

  // -------------------------------------------------------------------------
  // initial position helpers
  // -------------------------------------------------------------------------
  function [2:0] back;          // back-rank piece type by file
    input [2:0] bx;
    begin
      case (bx)
        3'd0:    back = 3'd4;   // rook
        3'd1:    back = 3'd2;   // knight
        3'd2:    back = 3'd3;   // bishop
        3'd3:    back = 3'd5;   // queen
        3'd4:    back = 3'd6;   // king
        3'd5:    back = 3'd3;   // bishop
        3'd6:    back = 3'd2;   // knight
        default: back = 3'd4;   // rook
      endcase
    end
  endfunction

  function [3:0] init_sq;       // starting piece for square {y,x}
    input [5:0] idx;
    begin
      case (idx[5:3])
        3'd0:    init_sq = {1'b1, back(idx[2:0])};  // black back rank
        3'd1:    init_sq = 4'b1001;                 // black pawns
        3'd6:    init_sq = 4'b0001;                 // white pawns
        3'd7:    init_sq = {1'b0, back(idx[2:0])};  // white back rank
        default: init_sq = 4'b0000;
      endcase
    end
  endfunction

  // -------------------------------------------------------------------------
  // game registers.  All sq[] reads go through whole-word wires.
  // -------------------------------------------------------------------------
  reg [3:0] sq [0:63];
  reg       turn;            // 0 = white to move
  reg       over;
  reg       winner;
  reg       have_src;
  reg [5:0] src;
  reg [2:0] ccx, ccy;        // cursor square (wraps)

  integer i;

  wire [5:0] cci = {ccy, ccx};
  wire [3:0] p   = sq[src];     // selected piece
  wire [3:0] d   = sq[cci];     // piece on the cursor square
  wire       pcol = p[3];

  // -------------------------------------------------------------------------
  // move geometry: 4-bit two's-complement deltas, manual absolute values.
  // -------------------------------------------------------------------------
  wire [3:0] dxs  = {1'b0, cci[2:0]} - {1'b0, src[2:0]};
  wire [3:0] dys  = {1'b0, cci[5:3]} - {1'b0, src[5:3]};
  wire [3:0] adx4 = dxs[3] ? (4'd0 - dxs) : dxs;
  wire [3:0] ady4 = dys[3] ? (4'd0 - dys) : dys;
  wire [2:0] adx  = adx4[2:0];
  wire [2:0] ady  = ady4[2:0];
  wire [2:0] dist = (adx > ady) ? adx : ady;

  // path occupancy for sliding pieces: intermediate squares 1..6 along the
  // (straight or diagonal) line from src toward the cursor square.
  wire [5:0] blk;
  genvar k;
  generate
    for (k = 1; k <= 6; k = k + 1) begin : g_path
      wire [2:0] ixk = (dxs == 4'd0) ? src[2:0]
                     : (dxs[3] ? (src[2:0] - k) : (src[2:0] + k));
      wire [2:0] iyk = (dys == 4'd0) ? src[5:3]
                     : (dys[3] ? (src[5:3] - k) : (src[5:3] + k));
      wire [3:0] cellk = sq[{iyk, ixk}];
      assign blk[k - 1] = (dist > k) && (cellk[2:0] != 3'd0);
    end
  endgenerate
  wire blocked = |blk;

  // -------------------------------------------------------------------------
  // legality of moving the selected piece to the cursor square
  // -------------------------------------------------------------------------
  wire dst_empty = (d[2:0] == 3'd0);
  wire dst_enemy = (d[2:0] != 3'd0) && (d[3] != pcol);
  wire dst_ok    = dst_empty || dst_enemy;

  wire kngeo   = ((adx == 3'd1) && (ady == 3'd2)) ||
                 ((adx == 3'd2) && (ady == 3'd1));
  wire kinggeo = (adx <= 3'd1) && (ady <= 3'd1);
  wire rookgeo = (adx == 3'd0) ^ (ady == 3'd0);
  wire bishgeo = (adx == ady) && (adx != 3'd0);

  // pawn helpers: white pushes toward y=0 (dys = -1), black toward y=7.
  wire dy_m1 = (dys == 4'b1111);
  wire dy_m2 = (dys == 4'b1110);
  wire dy_p1 = (dys == 4'd1);
  wire dy_p2 = (dys == 4'd2);

  wire [2:0] midy = pcol ? (src[5:3] + 3'd1) : (src[5:3] - 3'd1);
  wire [3:0] midw = sq[{midy, src[2:0]}];
  wire mid_empty  = (midw[2:0] == 3'd0);

  wire pawn_w = !pcol &&
      ( (dy_m1 && (adx == 3'd0) && dst_empty)
      || (dy_m2 && (adx == 3'd0) && (src[5:3] == 3'd6) && dst_empty && mid_empty)
      || (dy_m1 && (adx == 3'd1) && dst_enemy) );
  wire pawn_b = pcol &&
      ( (dy_p1 && (adx == 3'd0) && dst_empty)
      || (dy_p2 && (adx == 3'd0) && (src[5:3] == 3'd1) && dst_empty && mid_empty)
      || (dy_p1 && (adx == 3'd1) && dst_enemy) );

  reg legal;
  always @* begin
    case (p[2:0])
      3'd1:    legal = pawn_w | pawn_b;
      3'd2:    legal = dst_ok && kngeo;
      3'd3:    legal = dst_ok && bishgeo && !blocked;
      3'd4:    legal = dst_ok && rookgeo && !blocked;
      3'd5:    legal = dst_ok && (rookgeo || bishgeo) && !blocked;
      3'd6:    legal = dst_ok && kinggeo;
      default: legal = 1'b0;
    endcase
  end

  wire promo = (p[2:0] == 3'd1) &&
               (pcol ? (cci[5:3] == 3'd7) : (cci[5:3] == 3'd0));

  // -------------------------------------------------------------------------
  // main FSM: cursor, selection, move execution
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < 64; i = i + 1) sq[i] <= init_sq(i);
      turn     <= 1'b0;
      over     <= 1'b0;
      winner   <= 1'b0;
      have_src <= 1'b0;
      src      <= 6'd0;
      ccx      <= 3'd4;
      ccy      <= 3'd6;
    end else if (en) begin
      if (p_new) begin
        for (i = 0; i < 64; i = i + 1) sq[i] <= init_sq(i);
        turn     <= 1'b0;
        over     <= 1'b0;
        winner   <= 1'b0;
        have_src <= 1'b0;
      end else if (!over) begin
        if (p_up)    ccy <= ccy - 3'd1;
        if (p_down)  ccy <= ccy + 3'd1;
        if (p_left)  ccx <= ccx - 3'd1;
        if (p_right) ccx <= ccx + 3'd1;

        if (p_sel) begin
          if (!have_src) begin
            // pick up one of your own pieces
            if ((d[2:0] != 3'd0) && (d[3] == turn)) begin
              src      <= cci;
              have_src <= 1'b1;
            end
          end else if (cci == src) begin
            have_src <= 1'b0;                       // put it back down
          end else if ((d[2:0] != 3'd0) && (d[3] == turn)) begin
            src <= cci;                             // reselect
          end else if (legal) begin
            sq[cci]  <= promo ? {pcol, 3'd5} : p;   // auto-queen
            sq[src]  <= 4'd0;
            have_src <= 1'b0;
            if (d[2:0] == 3'd6) begin
              over   <= 1'b1;                       // king captured
              winner <= turn;
            end else begin
              turn <= ~turn;
            end
          end
          // illegal destination: keep the selection
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // piece glyphs: 8 row bytes per type, bit lx (bit 0 = leftmost pixel).
  // White pieces are outlines, black pieces are solid.
  // -------------------------------------------------------------------------
  // BITF_LUT
  function [7:0] glyph_w;
    input [5:0] s;   // {type[2:0], row[2:0]}
    begin
      case (s)
      // pawn
      6'h08: glyph_w = 8'h00;
      6'h09: glyph_w = 8'h00;
      6'h0A: glyph_w = 8'h18;
      6'h0B: glyph_w = 8'h18;
      6'h0C: glyph_w = 8'h24;
      6'h0D: glyph_w = 8'h24;
      6'h0E: glyph_w = 8'h7E;
      6'h0F: glyph_w = 8'h00;
      // knight
      6'h10: glyph_w = 8'h00;
      6'h11: glyph_w = 8'h1C;
      6'h12: glyph_w = 8'h2A;
      6'h13: glyph_w = 8'h37;
      6'h14: glyph_w = 8'h30;
      6'h15: glyph_w = 8'h28;
      6'h16: glyph_w = 8'h7C;
      6'h17: glyph_w = 8'h00;
      // bishop
      6'h18: glyph_w = 8'h00;
      6'h19: glyph_w = 8'h08;
      6'h1A: glyph_w = 8'h14;
      6'h1B: glyph_w = 8'h22;
      6'h1C: glyph_w = 8'h14;
      6'h1D: glyph_w = 8'h14;
      6'h1E: glyph_w = 8'h7E;
      6'h1F: glyph_w = 8'h00;
      // rook
      6'h20: glyph_w = 8'h00;
      6'h21: glyph_w = 8'h5A;
      6'h22: glyph_w = 8'h66;
      6'h23: glyph_w = 8'h24;
      6'h24: glyph_w = 8'h24;
      6'h25: glyph_w = 8'h24;
      6'h26: glyph_w = 8'h7E;
      6'h27: glyph_w = 8'h00;
      // queen
      6'h28: glyph_w = 8'h00;
      6'h29: glyph_w = 8'h99;
      6'h2A: glyph_w = 8'hA5;
      6'h2B: glyph_w = 8'h42;
      6'h2C: glyph_w = 8'h24;
      6'h2D: glyph_w = 8'h24;
      6'h2E: glyph_w = 8'h7E;
      6'h2F: glyph_w = 8'h00;
      // king
      6'h30: glyph_w = 8'h18;
      6'h31: glyph_w = 8'h24;
      6'h32: glyph_w = 8'h18;
      6'h33: glyph_w = 8'h24;
      6'h34: glyph_w = 8'h42;
      6'h35: glyph_w = 8'h42;
      6'h36: glyph_w = 8'h7E;
      6'h37: glyph_w = 8'h00;
      default: glyph_w = 8'h00;
      endcase
    end
  endfunction

  // BITF_LUT
  function [7:0] glyph_b;
    input [5:0] s;   // {type[2:0], row[2:0]}
    begin
      case (s)
      // pawn
      6'h08: glyph_b = 8'h00;
      6'h09: glyph_b = 8'h00;
      6'h0A: glyph_b = 8'h18;
      6'h0B: glyph_b = 8'h18;
      6'h0C: glyph_b = 8'h3C;
      6'h0D: glyph_b = 8'h3C;
      6'h0E: glyph_b = 8'h7E;
      6'h0F: glyph_b = 8'h00;
      // knight
      6'h10: glyph_b = 8'h00;
      6'h11: glyph_b = 8'h1C;
      6'h12: glyph_b = 8'h3E;
      6'h13: glyph_b = 8'h37;
      6'h14: glyph_b = 8'h30;
      6'h15: glyph_b = 8'h38;
      6'h16: glyph_b = 8'h7C;
      6'h17: glyph_b = 8'h00;
      // bishop
      6'h18: glyph_b = 8'h00;
      6'h19: glyph_b = 8'h08;
      6'h1A: glyph_b = 8'h1C;
      6'h1B: glyph_b = 8'h3E;
      6'h1C: glyph_b = 8'h1C;
      6'h1D: glyph_b = 8'h1C;
      6'h1E: glyph_b = 8'h7E;
      6'h1F: glyph_b = 8'h00;
      // rook
      6'h20: glyph_b = 8'h00;
      6'h21: glyph_b = 8'h5A;
      6'h22: glyph_b = 8'h7E;
      6'h23: glyph_b = 8'h3C;
      6'h24: glyph_b = 8'h3C;
      6'h25: glyph_b = 8'h3C;
      6'h26: glyph_b = 8'h7E;
      6'h27: glyph_b = 8'h00;
      // queen
      6'h28: glyph_b = 8'h00;
      6'h29: glyph_b = 8'h99;
      6'h2A: glyph_b = 8'hBD;
      6'h2B: glyph_b = 8'h7E;
      6'h2C: glyph_b = 8'h3C;
      6'h2D: glyph_b = 8'h3C;
      6'h2E: glyph_b = 8'h7E;
      6'h2F: glyph_b = 8'h00;
      // king
      6'h30: glyph_b = 8'h18;
      6'h31: glyph_b = 8'h3C;
      6'h32: glyph_b = 8'h18;
      6'h33: glyph_b = 8'h3C;
      6'h34: glyph_b = 8'h7E;
      6'h35: glyph_b = 8'h7E;
      6'h36: glyph_b = 8'h7E;
      6'h37: glyph_b = 8'h00;
      default: glyph_b = 8'h00;
      endcase
    end
  endfunction

  // -------------------------------------------------------------------------
  // raster: glyphs, dark-square weave, cursor and selection rings
  // -------------------------------------------------------------------------
  wire [2:0] cellx = r_x[5:3];
  wire [2:0] celly = r_y[5:3];
  wire [2:0] lx    = r_x[2:0];
  wire [2:0] ly    = r_y[2:0];
  wire [5:0] gci   = {celly, cellx};
  wire [3:0] gc    = sq[gci];

  wire [7:0] grow = gc[3] ? glyph_b({gc[2:0], ly}) : glyph_w({gc[2:0], ly});

  // after a win the winner's pieces blink
  wire winpiece = over && (gc[2:0] != 3'd0) && (gc[3] == winner);
  wire glyphpx  = grow[lx] && (!winpiece || frame_cnt[3]);

  wire dark   = cellx[0] ^ celly[0];
  wire dithpx = dark && (gc[2:0] == 3'd0) &&
                ((({1'b0, lx} + {1'b0, ly}) & 4'd3) == 4'd0);

  wire ring  = (lx == 3'd0) || (lx == 3'd7) || (ly == 3'd0) || (ly == 3'd7);
  wire curpx = !over && (cellx == ccx) && (celly == ccy) && ring && frame_cnt[2];
  wire selpx = !over && have_src && (gci == src) && ring;

  wire pix = glyphpx | dithpx | curpx | selpx;

  // -------------------------------------------------------------------------
  // pixel bus + status outputs
  // -------------------------------------------------------------------------
  assign px_x     = r_x;
  assign px_y     = r_y;
  assign frame    = en & r_clear;
  assign px_clear = en & r_clear;
  assign px_fill  = 1'b0;
  assign px_en    = en & ~r_clear & pix;

  assign o_turn   = turn;
  assign o_over   = over;
  assign o_winner = winner;
  assign o_sel    = have_src;
  assign o_src    = src;
  assign o_cursor = cci;
  assign o_piece  = d;

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
