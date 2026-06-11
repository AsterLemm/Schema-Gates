// ============================================================================
// game_doom3d.v  --  family: games  --  first-person maze raycaster, 32x32 px
// ----------------------------------------------------------------------------
// SchemaGates game module.  Self-contained file: every submodule used is
// embedded below (duplication across files is intentional, see repo README).
// Top module name == filename == catalog name.
// GENERATED FILE -- edit scripts/gen_game_doom3d.py / doom_template.v.
//
// DISPLAY CONTRACT (games-family pixel bus, see docs/games.md):
//   Each frame: 1-cycle px_clear pulse (display blanks), then a row-major
//   raster sweep of the whole screen.  While sweeping, px_en=1 lights the
//   pixel at (px_x,px_y).  The display latches pixels between clears.
//   px_fill is a 1-cycle pulse that sets the whole screen (effects only).
//   frame pulses once per frame, on the clear/fill cycle.
//   NOTE: unlike the fixed-rate games, this module casts its 32 view rays
//   BETWEEN sweeps, so frames have a variable length (the previous frame
//   stays latched on screen while the next one is computed).
//
// GAME:  Walk a 16x16 walled maze in first person.  The screen shows a
//   single-ray-per-column 3D view: wall slices scale with distance,
//   y-facing walls and far walls (over 8 cells) render as a checker
//   dither, the floor is a sparse diagonal weave, and a 2x2 crosshair
//   is XORed at the centre.  Hold btn_fwd/btn_back to walk (walls slide,
//   you cannot pass through them), btn_left/btn_right to turn.  btn_fire
//   flashes the screen for one frame (muzzle flash).  Reach the exit cell
//   at (13,13) and the screen flashes in celebration; btn_new restarts
//   from the entrance at any time.
//
// MAP/MATH ROMs (all generated, see scripts/gen_game_doom3d.py):
//   sinlut : 256-entry sine, 8-bit two's complement Q6 (64 = 1.0)
//   colofs : per-column ray angle offset, ~60 degree field of view
//   hgt    : step-count -> wall half-height (perspective divide)
//   maprow : the 16x16 maze, one 16-bit row per case (bit x = wall)
//   Positions are 12-bit 4.8 fixed point (cell = pos[11:8]); rays step
//   1/8 cell per clock, the player walks 1/4 cell per frame.
//
// VERIFIED WITH: tests/games/tb_game_doom3d.v (self-checking).
// ----------------------------------------------------------------------------
// define clk      input  255.170.0
// define rst      input  255.0.0
// define en       input  0.200.255
// define btn_fwd  input  0.255.0
// define btn_back input  0.255.0
// define btn_left input  0.255.0
// define btn_right input 0.255.0
// define btn_fire input  0.255.128
// define btn_new  input  255.255.0
// define px_x     output 255.255.0
// define px_y     output 255.255.0
// define px_en    output 255.255.255
// define px_clear output 128.128.255
// define px_fill  output 255.128.255
// define frame    output 170.170.170
// define o_posx   output 0.255.255
// define o_posy   output 0.255.255
// define o_ang    output 0.255.255
// define o_win    output 0.255.255
// ============================================================================

module game_doom3d (
  input  wire        clk,
  input  wire        rst,        // synchronous, active high
  input  wire        en,         // global enable (freezes game + raster)
  input  wire        btn_fwd,    // held: walk forward
  input  wire        btn_back,   // held: walk backward
  input  wire        btn_left,   // held: turn left
  input  wire        btn_right,  // held: turn right
  input  wire        btn_fire,
  input  wire        btn_new,
  output wire [4:0]  px_x,
  output wire [4:0]  px_y,
  output wire        px_en,
  output wire        px_clear,
  output wire        px_fill,
  output wire        frame,
  output wire [11:0] o_posx,     // player x, 4.8 fixed point
  output wire [11:0] o_posy,     // player y, 4.8 fixed point
  output wire [7:0]  o_ang,      // heading, 256 units per turn
  output wire        o_win
);

  // -------------------------------------------------------------------------
  // frame machine: move, cast all 32 columns, clear, sweep, repeat.
  // -------------------------------------------------------------------------
  localparam [1:0] M_MOVE  = 2'd0;  // 1 clk : apply turning/walking
  localparam [1:0] M_CAST  = 2'd1;  // cast rays for columns 0..31
  localparam [1:0] M_CLEAR = 2'd2;  // 1 clk : px_clear / px_fill pulse
  localparam [1:0] M_SWEEP = 2'd3;  // 32x32 raster sweep

  // -------------------------------------------------------------------------
  // button conditioning (sync + rising-edge pulse / held level)
  // -------------------------------------------------------------------------
  wire p_fire, p_new;
  wire l_fwd, l_back, l_left, l_right;
  wire p_unused0, p_unused1, p_unused2, p_unused3;
  wire l_unused0, l_unused1;

  game_btn u_b_fwd   (.clk(clk), .rst(rst), .d(btn_fwd),   .pulse(p_unused0), .level(l_fwd));
  game_btn u_b_back  (.clk(clk), .rst(rst), .d(btn_back),  .pulse(p_unused1), .level(l_back));
  game_btn u_b_left  (.clk(clk), .rst(rst), .d(btn_left),  .pulse(p_unused2), .level(l_left));
  game_btn u_b_right (.clk(clk), .rst(rst), .d(btn_right), .pulse(p_unused3), .level(l_right));
  game_btn u_b_fire  (.clk(clk), .rst(rst), .d(btn_fire),  .pulse(p_fire),    .level(l_unused0));
  game_btn u_b_new   (.clk(clk), .rst(rst), .d(btn_new),   .pulse(p_new),     .level(l_unused1));

  // -------------------------------------------------------------------------
  // sine table: sin(2*pi*a/256) in 8-bit two's complement Q6 (64 = 1.0).
  // cos(a) = sinlut(a + 64).
  // -------------------------------------------------------------------------
  // BITF_LUT
  function [7:0] sinlut;
    input [7:0] a;
    begin
      case (a)
@@SINLUT@@
      default: sinlut = 8'h00;
      endcase
    end
  endfunction

  // -------------------------------------------------------------------------
  // per-column ray angle offset: ~60 degree FOV over 32 columns,
  // round((col - 15.5) * 4/3), 8-bit two's complement.
  // -------------------------------------------------------------------------
  // BITF_LUT
  function [7:0] colofs;
    input [4:0] c;
    begin
      case (c)
@@COLOFS@@
      default: colofs = 8'h00;
      endcase
    end
  endfunction

  // -------------------------------------------------------------------------
  // perspective divide: ray step count -> wall half-height in pixels,
  // max(1, min(15, round(112 / s))); hgt(0) = 15.
  // -------------------------------------------------------------------------
  // BITF_LUT
  function [3:0] hgt;
    input [7:0] s;
    begin
      case (s)
@@HGT@@
      default: hgt = 4'd1;
      endcase
    end
  endfunction

  // -------------------------------------------------------------------------
  // the maze: 16 rows of 16 cells, bit x of row y = wall at (x,y).
  // Border is solid; entrance cell (2,2); exit cell (13,13).
  // -------------------------------------------------------------------------
  // BITF_DECODER
  function [15:0] maprow;
    input [3:0] my;
    begin
      case (my)
@@MAPROW@@
      endcase
    end
  endfunction

  // -------------------------------------------------------------------------
  // game registers
  // -------------------------------------------------------------------------
  reg [1:0]  mstate;
  reg [11:0] posx, posy;     // player position, 4.8 fixed point
  reg [7:0]  ang;            // heading
  reg        won;
  reg        fire_req;       // latched btn_fire, consumed at next M_CLEAR

  reg [4:0]  col;            // column being cast
  reg        cinit;          // load ray registers for this column
  reg [11:0] rx, ry;         // ray position, 4.8 fixed point
  reg [3:0]  pcy;            // ray cell-y one step ago (wall side detect)
  reg [7:0]  scnt;           // ray step count

  reg [3:0]  colh   [0:31];  // wall half-height per column (0 = no wall)
  reg        colsd  [0:31];  // hit a y-facing wall side (shaded)
  reg        colfar [0:31];  // hit beyond 8 cells (distance fog)

  reg [4:0]  r_x, r_y;       // raster position
  reg [7:0]  frame_cnt;

  integer i;

  // -------------------------------------------------------------------------
  // walking: 1/4 cell per frame along the heading, with axis-separated
  // wall sliding.  The y test uses the cell the x axis actually settled
  // in, so the final (x,y) cell is always verified open.
  // -------------------------------------------------------------------------
  wire [7:0]  csp = sinlut(ang + 8'd64);
  wire [7:0]  snp = sinlut(ang);
  wire [11:0] mdx = {{4{csp[7]}}, csp};
  wire [11:0] mdy = {{4{snp[7]}}, snp};

  reg  [11:0] tx, ty;
  reg         domove;
  always @* begin
    tx     = posx;
    ty     = posy;
    domove = 1'b0;
    if (l_fwd) begin
      tx = posx + mdx;  ty = posy + mdy;  domove = 1'b1;
    end else if (l_back) begin
      tx = posx - mdx;  ty = posy - mdy;  domove = 1'b1;
    end
  end

  wire [15:0] mrow_x = maprow(posy[11:8]);
  wire        xok    = domove && !mrow_x[tx[11:8]];
  wire [3:0]  effx   = xok ? tx[11:8] : posx[11:8];
  wire [15:0] mrow_y = maprow(ty[11:8]);
  wire        yok    = domove && !mrow_y[effx];

  // -------------------------------------------------------------------------
  // ray stepping for the column currently being cast: 1/8 cell per clock
  // along ang + colofs(col), until a wall cell is entered (or 200 steps).
  // -------------------------------------------------------------------------
  wire [7:0]  ra   = ang + colofs(col);
  wire [7:0]  cs   = sinlut(ra + 8'd64);
  wire [7:0]  sn   = sinlut(ra);
  wire [7:0]  csh  = {cs[7], cs[7:1]};       // arithmetic >> 1
  wire [7:0]  snh  = {sn[7], sn[7:1]};
  wire [11:0] rdx  = {{4{csh[7]}}, csh};
  wire [11:0] rdy  = {{4{snh[7]}}, snh};
  wire [15:0] crow   = maprow(ry[11:8]);
  wire        hitnow = crow[rx[11:8]];

  // -------------------------------------------------------------------------
  // frame machine
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst) begin
      mstate    <= M_MOVE;
      posx      <= 12'h280;          // entrance (2.5, 2.5)
      posy      <= 12'h280;
      ang       <= 8'd0;
      won       <= 1'b0;
      fire_req  <= 1'b0;
      col       <= 5'd0;
      cinit     <= 1'b1;
      rx        <= 12'd0;
      ry        <= 12'd0;
      pcy       <= 4'd0;
      scnt      <= 8'd0;
      r_x       <= 5'd0;
      r_y       <= 5'd0;
      frame_cnt <= 8'd0;
      for (i = 0; i < 32; i = i + 1) begin
        colh[i]   <= 4'd0;
        colsd[i]  <= 1'b0;
        colfar[i] <= 1'b0;
      end
    end else if (en) begin
      if (p_fire) fire_req <= 1'b1;
      if (p_new) begin
        posx <= 12'h280;
        posy <= 12'h280;
        ang  <= 8'd0;
        won  <= 1'b0;
      end else begin
        case (mstate)
          M_MOVE: begin
            if (!won) begin
              if (l_left)       ang <= ang - 8'd2;
              else if (l_right) ang <= ang + 8'd2;
              if (xok) posx <= tx;
              if (yok) posy <= ty;
              if ((posx[11:8] == 4'd13) && (posy[11:8] == 4'd13))
                won <= 1'b1;
            end
            col    <= 5'd0;
            cinit  <= 1'b1;
            mstate <= M_CAST;
          end

          M_CAST: begin
            if (cinit) begin
              rx    <= posx;
              ry    <= posy;
              pcy   <= posy[11:8];
              scnt  <= 8'd0;
              cinit <= 1'b0;
            end else if (hitnow) begin
              colh[col]   <= hgt(scnt);
              colsd[col]  <= (pcy != ry[11:8]);
              colfar[col] <= (scnt > 8'd64);
              if (col == 5'd31) begin
                mstate <= M_CLEAR;
              end else begin
                col   <= col + 5'd1;
                cinit <= 1'b1;
              end
            end else if (scnt == 8'd200) begin
              colh[col]   <= 4'd0;            // open horizon
              colsd[col]  <= 1'b0;
              colfar[col] <= 1'b1;
              if (col == 5'd31) begin
                mstate <= M_CLEAR;
              end else begin
                col   <= col + 5'd1;
                cinit <= 1'b1;
              end
            end else begin
              pcy  <= ry[11:8];
              rx   <= rx + rdx;
              ry   <= ry + rdy;
              scnt <= scnt + 8'd1;
            end
          end

          M_CLEAR: begin
            frame_cnt <= frame_cnt + 8'd1;
            fire_req  <= 1'b0;
            r_x       <= 5'd0;
            r_y       <= 5'd0;
            mstate    <= M_SWEEP;
          end

          default: begin                       // M_SWEEP
            if (r_x == 5'd31) begin
              r_x <= 5'd0;
              if (r_y == 5'd31) begin
                r_y    <= 5'd0;
                mstate <= M_MOVE;
              end else begin
                r_y <= r_y + 5'd1;
              end
            end else begin
              r_x <= r_x + 5'd1;
            end
          end
        endcase
      end
    end
  end

  // -------------------------------------------------------------------------
  // pixel function: wall slice for this column, dither shading, floor weave,
  // centre crosshair (XOR so it stays visible against walls).
  // -------------------------------------------------------------------------
  wire [3:0] ch    = colh[r_x];
  wire       shd   = colsd[r_x] | colfar[r_x];
  wire [4:0] htop  = 5'd16 - {1'b0, ch};
  wire [4:0] hbot  = 5'd15 + {1'b0, ch};

  wire wall    = (ch != 4'd0) && (r_y >= htop) && (r_y <= hbot);
  wire wallpx  = wall && (!shd || (r_x[0] ^ r_y[0]));
  wire floorpx = (r_y > hbot) && (((r_x + r_y) & 5'd3) == 5'd0);
  wire cross   = ((r_x == 5'd15) || (r_x == 5'd16)) &&
                 ((r_y == 5'd15) || (r_y == 5'd16));

  wire pix = (wallpx | floorpx) ^ cross;

  wire atclear  = (mstate == M_CLEAR);
  wire winflash = won && frame_cnt[2];

  // -------------------------------------------------------------------------
  // pixel bus + status outputs
  // -------------------------------------------------------------------------
  assign px_x     = r_x;
  assign px_y     = r_y;
  assign frame    = en & atclear;
  assign px_clear = en & atclear & ~(fire_req | winflash);
  assign px_fill  = en & atclear &  (fire_req | winflash);
  assign px_en    = en & (mstate == M_SWEEP) & pix;

  assign o_posx = posx;
  assign o_posy = posy;
  assign o_ang  = ang;
  assign o_win  = won;

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
