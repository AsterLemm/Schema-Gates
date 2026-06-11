// ============================================================================
// game_tictactoe_lite.v  --  family: games  --  tic-tac-toe, no display
// ----------------------------------------------------------------------------
// SchemaGates game module.  Self-contained file: every submodule used is
// embedded below (duplication across files is intentional, see repo README).
// Top module name == filename == catalog name.
//
// LITE VARIANT (build-your-own-display):
//   Same game brain as game_tictactoe.v, but there is NO pixel bus.  The
//   whole board fits in three 9-bit lamp buses, one bit per cell, so you can
//   wire each bit to its own lamp / LED on the canvas and lay the 3x3 grid
//   out yourself.  Cell numbering (bit i of every bus):
//        0 | 1 | 2        i = row*3 + col, row 0 at the top,
//       ---+---+---                        col 0 on the left
//        3 | 4 | 5
//       ---+---+---
//        6 | 7 | 8
//     o_x    bit i high = cell i holds an X
//     o_o    bit i high = cell i holds an O
//     o_cur  one-hot cursor position (drive your cursor lamp / blinker)
//     o_line bits of the winning line, 0 until somebody wins (flash it!)
//
// GAME:  Move the cursor with btn_up/down/left/right (clamps at the edges),
//   drop a mark with btn_place.  X always starts.  Occupied cells reject the
//   place.  After a win or a draw the board freezes; btn_new restarts (the
//   cursor stays where it was).
//
// VERIFIED WITH: tests/games/tb_game_tictactoe_lite.v (self-checking).
// ----------------------------------------------------------------------------
// define clk       input  255.170.0
// define rst       input  255.0.0
// define en        input  0.200.255
// define btn_up    input  0.255.0
// define btn_down  input  0.255.0
// define btn_left  input  0.255.0
// define btn_right input  0.255.0
// define btn_place input  0.255.128
// define btn_new   input  255.255.0
// define o_x       output 0.255.255
// define o_o       output 255.128.0
// define o_cur     output 255.255.0
// define o_line    output 255.64.64
// define o_turn    output 170.170.170
// define o_win     output 255.64.64
// define o_winner  output 255.64.64
// define o_draw    output 170.170.170
// ============================================================================

module game_tictactoe_lite (
  input  wire       clk,
  input  wire       rst,        // synchronous, active high
  input  wire       en,         // global enable (freezes the game)
  input  wire       btn_up,
  input  wire       btn_down,
  input  wire       btn_left,
  input  wire       btn_right,
  input  wire       btn_place,
  input  wire       btn_new,
  output wire [8:0] o_x,        // bit i: cell i holds an X
  output wire [8:0] o_o,        // bit i: cell i holds an O
  output wire [8:0] o_cur,      // one-hot cursor cell
  output wire [8:0] o_line,     // winning line cells (0 until o_win)
  output wire       o_turn,     // 0 = X to move, 1 = O to move
  output wire       o_win,
  output wire       o_winner,   // valid when o_win: 0 = X won, 1 = O won
  output wire       o_draw
);

  // -------------------------------------------------------------------------
  // game states
  // -------------------------------------------------------------------------
  localparam [1:0] ST_PLAY = 2'd0;
  localparam [1:0] ST_WIN  = 2'd1;
  localparam [1:0] ST_DRAW = 2'd2;

  // -------------------------------------------------------------------------
  // button conditioning (sync + rising-edge pulse)
  // -------------------------------------------------------------------------
  wire p_up, p_down, p_left, p_right, p_place, p_new;
  wire l_unused0, l_unused1, l_unused2, l_unused3, l_unused4, l_unused5;

  game_btn u_b_up    (.clk(clk), .rst(rst), .d(btn_up),    .pulse(p_up),    .level(l_unused0));
  game_btn u_b_down  (.clk(clk), .rst(rst), .d(btn_down),  .pulse(p_down),  .level(l_unused1));
  game_btn u_b_left  (.clk(clk), .rst(rst), .d(btn_left),  .pulse(p_left),  .level(l_unused2));
  game_btn u_b_right (.clk(clk), .rst(rst), .d(btn_right), .pulse(p_right), .level(l_unused3));
  game_btn u_b_place (.clk(clk), .rst(rst), .d(btn_place), .pulse(p_place), .level(l_unused4));
  game_btn u_b_new   (.clk(clk), .rst(rst), .d(btn_new),   .pulse(p_new),   .level(l_unused5));

  // -------------------------------------------------------------------------
  // board state
  // -------------------------------------------------------------------------
  reg [17:0] board;     // cell i = bits [2i+1:2i]; 00 empty 01 X 10 O
  reg        turn;      // 0 = X, 1 = O
  reg [1:0]  gstate;
  reg        winner;
  reg [1:0]  cx, cy;    // cursor cell 0..2

  // cursor cell index 0..8  (ci = cy*3 + cx, built from shifts/adds only)
  wire [3:0] ci = {1'b0, cy, 1'b0} + {2'b00, cy} + {2'b00, cx};

  // per-cell occupancy masks
  wire [1:0] c0 = board[ 1: 0];
  wire [1:0] c1 = board[ 3: 2];
  wire [1:0] c2 = board[ 5: 4];
  wire [1:0] c3 = board[ 7: 6];
  wire [1:0] c4 = board[ 9: 8];
  wire [1:0] c5 = board[11:10];
  wire [1:0] c6 = board[13:12];
  wire [1:0] c7 = board[15:14];
  wire [1:0] c8 = board[17:16];

  wire [8:0] xm = { c8==2'b01, c7==2'b01, c6==2'b01, c5==2'b01, c4==2'b01,
                    c3==2'b01, c2==2'b01, c1==2'b01, c0==2'b01 };
  wire [8:0] om = { c8==2'b10, c7==2'b10, c6==2'b10, c5==2'b10, c4==2'b10,
                    c3==2'b10, c2==2'b10, c1==2'b10, c0==2'b10 };

  // three-in-a-row test over a 9-bit occupancy mask
  function line3;
    input [8:0] m;
    input [3:0] a;
    input [3:0] b;
    input [3:0] c;
    begin
      line3 = m[a] & m[b] & m[c];
    end
  endfunction

  // 8 lines: rows, columns, diagonals
  wire [7:0] xl = { line3(xm,4'd2,4'd4,4'd6), line3(xm,4'd0,4'd4,4'd8),
                    line3(xm,4'd2,4'd5,4'd8), line3(xm,4'd1,4'd4,4'd7),
                    line3(xm,4'd0,4'd3,4'd6), line3(xm,4'd6,4'd7,4'd8),
                    line3(xm,4'd3,4'd4,4'd5), line3(xm,4'd0,4'd1,4'd2) };
  wire [7:0] ol = { line3(om,4'd2,4'd4,4'd6), line3(om,4'd0,4'd4,4'd8),
                    line3(om,4'd2,4'd5,4'd8), line3(om,4'd1,4'd4,4'd7),
                    line3(om,4'd0,4'd3,4'd6), line3(om,4'd6,4'd7,4'd8),
                    line3(om,4'd3,4'd4,4'd5), line3(om,4'd0,4'd1,4'd2) };

  wire x_wins   = |xl;
  wire o_wins_w = |ol;
  wire all_full = &(xm | om);

  // mask of the winning line(s) -- exported on o_line once the win latches
  wire [7:0] wl = xl | ol;
  wire [8:0] wmask = (wl[0] ? 9'h007 : 9'h000) | (wl[1] ? 9'h038 : 9'h000)
                   | (wl[2] ? 9'h1C0 : 9'h000) | (wl[3] ? 9'h049 : 9'h000)
                   | (wl[4] ? 9'h092 : 9'h000) | (wl[5] ? 9'h124 : 9'h000)
                   | (wl[6] ? 9'h111 : 9'h000) | (wl[7] ? 9'h054 : 9'h000);

  // -------------------------------------------------------------------------
  // game sequencing
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst) begin
      board  <= 18'd0;
      turn   <= 1'b0;
      gstate <= ST_PLAY;
      winner <= 1'b0;
      cx     <= 2'd0;
      cy     <= 2'd0;
    end else if (en) begin
      if (p_new) begin
        board  <= 18'd0;
        turn   <= 1'b0;
        gstate <= ST_PLAY;
        winner <= 1'b0;
      end else begin
        // cursor always movable
        if (p_up    && cy != 2'd0) cy <= cy - 2'd1;
        if (p_down  && cy != 2'd2) cy <= cy + 2'd1;
        if (p_left  && cx != 2'd0) cx <= cx - 2'd1;
        if (p_right && cx != 2'd2) cx <= cx + 2'd1;

        if (gstate == ST_PLAY) begin
          // result detection (sees the board one cycle after a move lands)
          if (x_wins | o_wins_w) begin
            gstate <= ST_WIN;
            winner <= o_wins_w;     // if O completed a line, O is the winner
          end else if (all_full) begin
            gstate <= ST_DRAW;
          end else if (p_place && board[{ci,1'b0} +: 2] == 2'b00) begin
            board[{ci,1'b0} +: 2] <= turn ? 2'b10 : 2'b01;
            turn <= ~turn;
          end
        end
      end
    end
  end

  // -------------------------------------------------------------------------
  // lamp-bus output decode -- this replaces the whole raster stage of
  // game_tictactoe.v.  One bit per cell, see the numbering map up top.
  // -------------------------------------------------------------------------
  assign o_x = xm;
  assign o_o = om;

  assign o_cur = { ci == 4'd8, ci == 4'd7, ci == 4'd6,
                   ci == 4'd5, ci == 4'd4, ci == 4'd3,
                   ci == 4'd2, ci == 4'd1, ci == 4'd0 };

  assign o_line   = (gstate == ST_WIN) ? wmask : 9'd0;
  assign o_turn   = turn;
  assign o_win    = (gstate == ST_WIN);
  assign o_winner = winner;
  assign o_draw   = (gstate == ST_DRAW);

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
