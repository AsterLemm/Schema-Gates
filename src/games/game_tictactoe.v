// ============================================================================
// game_tictactoe.v  --  family: games  --  two-player tic-tac-toe, 24x24 px
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
// GAME:  Move the cursor with btn_up/down/left/right, drop a mark with
//   btn_place.  X always starts.  The winning line flashes; btn_new restarts.
//   Screen is 24x24: nine 8x8 cells (7x7 drawable + 1px grid line).
//
// VERIFIED WITH: tests/games/tb_game_tictactoe.v (self-checking).
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
// define px_x      output 255.255.0
// define px_y      output 255.255.0
// define px_en     output 255.255.255
// define px_clear  output 128.128.255
// define px_fill   output 255.128.255
// define frame     output 170.170.170
// define o_board   output 0.255.255
// define o_turn    output 0.255.255
// define o_win     output 255.64.64
// define o_winner  output 255.64.64
// define o_draw    output 255.64.64
// ============================================================================

module game_tictactoe (
  input  wire        clk,
  input  wire        rst,        // synchronous, active high
  input  wire        en,         // global enable (freezes game + raster)
  input  wire        btn_up,
  input  wire        btn_down,
  input  wire        btn_left,
  input  wire        btn_right,
  input  wire        btn_place,
  input  wire        btn_new,
  output wire [4:0]  px_x,
  output wire [4:0]  px_y,
  output wire        px_en,
  output wire        px_clear,
  output wire        px_fill,
  output wire        frame,
  output wire [17:0] o_board,    // cell i = bits [2i+1:2i]; 00 empty 01 X 10 O
  output wire        o_turn,     // 0 = X to move, 1 = O to move
  output wire        o_win,
  output wire        o_winner,   // valid when o_win: 0 = X won, 1 = O won
  output wire        o_draw
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
  reg [17:0] board;
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

  // highlight mask of the winning line(s)
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
  // raster scan: 24 x 24, clear pulse then row-major sweep
  // -------------------------------------------------------------------------
  reg       r_clear;
  reg [4:0] r_x;
  reg [4:0] r_y;
  reg [7:0] frame_cnt;

  always @(posedge clk) begin
    if (rst) begin
      r_clear   <= 1'b1;
      r_x       <= 5'd0;
      r_y       <= 5'd0;
      frame_cnt <= 8'd0;
    end else if (en) begin
      if (r_clear) begin
        r_clear   <= 1'b0;
        r_x       <= 5'd0;
        r_y       <= 5'd0;
        frame_cnt <= frame_cnt + 8'd1;
      end else if (r_x == 5'd23) begin
        r_x <= 5'd0;
        if (r_y == 5'd23) begin
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
  // pixel function (combinational on the raster position)
  // -------------------------------------------------------------------------
  wire [1:0] gcx = r_x[4:3];                     // cell column 0..2
  wire [1:0] gcy = r_y[4:3];                     // cell row    0..2
  wire [2:0] lx  = r_x[2:0];                     // pixel inside the cell
  wire [2:0] ly  = r_y[2:0];
  wire [3:0] gci = {1'b0, gcy, 1'b0} + {2'b00, gcy} + {2'b00, gcx};
  wire [1:0] gc  = board[{gci,1'b0} +: 2];

  wire grid = ((lx == 3'd7) && (gcx != 2'd2)) ||
              ((ly == 3'd7) && (gcy != 2'd2));
  wire in7  = (lx != 3'd7) && (ly != 3'd7);      // 7x7 drawable area

  // X glyph: the two diagonals of the 7x7 box
  wire g_x  = in7 && ((lx == ly) || (({1'b0,lx} + {1'b0,ly}) == 4'd6));
  // O glyph: square ring from (1,1) to (5,5)
  wire g_o  = in7 && ( ((lx==3'd1 || lx==3'd5) && (ly>=3'd1) && (ly<=3'd5)) ||
                       ((ly==3'd1 || ly==3'd5) && (lx>=3'd1) && (lx<=3'd5)) );

  wire blink = frame_cnt[3];

  wire glyph = (gstate == ST_WIN && wmask[gci]) ? (blink ? in7 : 1'b0)
             : (gc == 2'b01) ? g_x
             : (gc == 2'b10) ? g_o
             : 1'b0;

  wire curhere   = (gcx == cx) && (gcy == cy);
  wire curbox    = in7 && (lx==3'd0 || lx==3'd6 || ly==3'd0 || ly==3'd6);
  wire cursor_px = (gstate == ST_PLAY) && curhere && curbox && blink;

  wire pix = grid | glyph | cursor_px;

  // -------------------------------------------------------------------------
  // pixel bus + status outputs
  // -------------------------------------------------------------------------
  assign px_x     = r_x;
  assign px_y     = r_y;
  assign frame    = en & r_clear;
  assign px_clear = en & r_clear;
  assign px_fill  = 1'b0;
  assign px_en    = en & ~r_clear & pix;

  assign o_board  = board;
  assign o_turn   = turn;
  assign o_win    = (gstate == ST_WIN);
  assign o_winner = winner;
  assign o_draw   = (gstate == ST_DRAW);

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
