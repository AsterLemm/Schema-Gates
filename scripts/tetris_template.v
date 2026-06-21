// ============================================================================
// game_tetris.v  --  family: games  --  falling-blocks game, 12x22 px
// ----------------------------------------------------------------------------
// SchemaGates game module.  Self-contained file: every submodule used is
// embedded below (duplication across files is intentional, see repo README).
// Top module name == filename == catalog name.
// GENERATED FILE -- edit scripts/gen_game_tetris.py / tetris_template.v.
//
// DISPLAY CONTRACT (games-family pixel bus, see docs/games.md):
//   Each frame: 1-cycle px_clear pulse (display blanks), then a row-major
//   raster sweep of the whole screen.  While sweeping, px_en=1 lights the
//   pixel at (px_x,px_y).  The display latches pixels between clears.
//   px_fill is a 1-cycle pulse that sets the whole screen (effects only).
//   frame pulses once per frame, on the clear/fill cycle.
//
// GAME:  Classic falling tetrominoes on a 10x20 field drawn inside a well
//   (screen columns 1..10, rows 1..20; column 0/11 and row 21 are walls,
//   row 0 is open sky).  btn_left/right shift the piece, btn_rot rotates
//   clockwise (no wall kicks -- a blocked rotation is simply ignored),
//   btn_down soft-drops while held, btn_drop hard-drops.  Completed rows
//   are cleared and counted on o_lines; the next piece type is previewed
//   on o_next.  Stacking out at the spawn cell ends the game (the field
//   blinks); btn_new restarts at any time.  speed[1:0] sets gravity:
//   0 = slowest (every 8 frames) .. 3 = every frame.
//
// PIECES:  7 tetrominoes (I O T S Z J L), 4 rotations each, stored as
//   4x4 bitmaps in the BITF_LUT below (sel = {type[2:0], rot[1:0]},
//   bitmap bit index = {ly[1:0], lx[1:0]}, bit 0 = top-left).
//
// VERIFIED WITH: tests/games/tb_game_tetris.v (self-checking).
// ----------------------------------------------------------------------------
// define clk       input  255.170.0
// define rst       input  255.0.0
// define en        input  0.200.255
// define btn_left  input  0.255.0
// define btn_right input  0.255.0
// define btn_rot   input  0.255.128
// define btn_down  input  0.255.0
// define btn_drop  input  0.255.128
// define btn_new   input  255.255.0
// define speed     input  0.200.255
// define px_x      output 255.255.0
// define px_y      output 255.255.0
// define px_en     output 255.255.255
// define px_clear  output 128.128.255
// define px_fill   output 255.128.255
// define frame     output 170.170.170
// define o_lines   output 0.255.255
// define o_pieces  output 0.255.255
// define o_next    output 0.255.255
// define o_over    output 255.64.64
// ============================================================================

module game_tetris (
  input  wire        clk,
  input  wire        rst,        // synchronous, active high
  input  wire        en,         // global enable (freezes game + raster)
  input  wire        btn_left,
  input  wire        btn_right,
  input  wire        btn_rot,    // rotate clockwise
  input  wire        btn_down,   // soft drop (held)
  input  wire        btn_drop,   // hard drop
  input  wire        btn_new,
  input  wire [1:0]  speed,      // 0 slow .. 3 fast (gravity rate)
  output wire [3:0]  px_x,
  output wire [4:0]  px_y,
  output wire        px_en,
  output wire        px_clear,
  output wire        px_fill,
  output wire        frame,
  output wire [7:0]  o_lines,    // cleared rows (saturates at 255)
  output wire [7:0]  o_pieces,   // pieces spawned (saturates at 255)
  output wire [2:0]  o_next,     // next piece type 0..6 (I O T S Z J L)
  output wire        o_over
);

  // -------------------------------------------------------------------------
  // game states
  // -------------------------------------------------------------------------
  localparam [2:0] ST_NEW     = 3'd0;  // roll the very first "next" piece
  localparam [2:0] ST_SPAWN   = 3'd1;  // try to place "next" at the top
  localparam [2:0] ST_PICK    = 3'd2;  // roll a fresh "next" piece
  localparam [2:0] ST_FALL    = 3'd3;  // normal play
  localparam [2:0] ST_DROP    = 3'd4;  // hard drop, 1 cell per clock
  localparam [2:0] ST_LOCK    = 3'd5;  // merge piece into the field (1 clk)
  localparam [2:0] ST_LINECHK = 3'd6;  // scan rows bottom-up, 1 row per clock
  localparam [2:0] ST_OVER    = 3'd7;

  // -------------------------------------------------------------------------
  // button conditioning (sync + rising-edge pulse / held level)
  // -------------------------------------------------------------------------
  wire p_left, p_right, p_rot, p_down, p_drop, p_new;
  wire l_down;
  wire l_unused0, l_unused1, l_unused2, l_unused3, l_unused4;

  game_btn u_b_left  (.clk(clk), .rst(rst), .d(btn_left),  .pulse(p_left),  .level(l_unused0));
  game_btn u_b_right (.clk(clk), .rst(rst), .d(btn_right), .pulse(p_right), .level(l_unused1));
  game_btn u_b_rot   (.clk(clk), .rst(rst), .d(btn_rot),   .pulse(p_rot),   .level(l_unused2));
  game_btn u_b_down  (.clk(clk), .rst(rst), .d(btn_down),  .pulse(p_down),  .level(l_down));
  game_btn u_b_drop  (.clk(clk), .rst(rst), .d(btn_drop),  .pulse(p_drop),  .level(l_unused3));
  game_btn u_b_new   (.clk(clk), .rst(rst), .d(btn_new),   .pulse(p_new),   .level(l_unused4));

  wire [1:0] s_speed;
  game_sync2 u_sp0 (.clk(clk), .d(speed[0]), .q(s_speed[0]));
  game_sync2 u_sp1 (.clk(clk), .d(speed[1]), .q(s_speed[1]));

  wire [15:0] rnd;
  game_lfsr16 u_lfsr (.clk(clk), .rst(rst), .en(en), .q(rnd));

  // -------------------------------------------------------------------------
  // raster generator: 12x22 row-major sweep with a 1-cycle clear between
  // frames.  frame_cnt drives blink effects and the gravity tick.
  // -------------------------------------------------------------------------
  reg [3:0] r_x;
  reg [4:0] r_y;
  reg       r_clear;
  reg [7:0] frame_cnt;

  always @(posedge clk) begin
    if (rst) begin
      r_x       <= 4'd0;
      r_y       <= 5'd0;
      r_clear   <= 1'b1;
      frame_cnt <= 8'd0;
    end else if (en) begin
      if (r_clear) begin
        r_clear   <= 1'b0;
        r_x       <= 4'd0;
        r_y       <= 5'd0;
        frame_cnt <= frame_cnt + 8'd1;
      end else if (r_x == 4'd11) begin
        r_x <= 4'd0;
        if (r_y == 5'd21) begin
          r_y     <= 5'd0;
          r_clear <= 1'b1;
        end else begin
          r_y <= r_y + 5'd1;
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

  // gravity tick: once per frame at the selected rate, or every frame while
  // soft drop is held.  Latched into grav_due and serviced by the FSM.
  wire tick_grav = r_clear && (((frame_cnt & smask) == 8'd0) || l_down);

  // -------------------------------------------------------------------------
  // piece bitmap LUT: 7 tetrominoes x 4 clockwise rotations as 4x4 bitmaps.
  // sel = {type[2:0], rot[1:0]}; bit index = {ly[1:0], lx[1:0]}.
  // -------------------------------------------------------------------------
  // BITF_LUT
  function [15:0] mino;
    input [4:0] sel;
    begin
      case (sel)
@@LUT@@
      default: mino = 16'h0000;
      endcase
    end
  endfunction

  // row base offset: r10(r) = 10*r, built from shifts/adds only.
  function [7:0] r10;
    input [7:0] r;
    begin
      r10 = {r[4:0], 3'b000} + {2'b00, r[4:0], 1'b0};
    end
  endfunction

  // -------------------------------------------------------------------------
  // game registers.  The 10x20 field is one 10-bit reg per row (row 0 = top);
  // a flat 200-bit mirror feeds the hit checkers and the raster.
  // -------------------------------------------------------------------------
  reg [9:0]  frow [0:19];
  reg [2:0]  state;
  reg [2:0]  cur_type, nxt_type;
  reg [1:0]  rot;
  reg [5:0]  posx, posy;     // piece origin, 6-bit two's complement
  reg [4:0]  lrow;           // row scanned by ST_LINECHK
  reg [7:0]  lines, pieces;
  reg        req_rot, req_l, req_r, req_drop, grav_due;

  integer i;

  wire [199:0] field_flat;
  genvar gr;
  generate
    for (gr = 0; gr < 20; gr = gr + 1) begin : g_fr
      assign field_flat[((gr << 3) + (gr << 1)) +: 10] = frow[gr];
    end
  endgenerate

  wire [15:0] bm_cur  = mino({cur_type, rot});
  wire [15:0] bm_rot  = mino({cur_type, rot + 2'd1});
  wire [15:0] bm_nxt0 = mino({nxt_type, 2'b00});

  // -------------------------------------------------------------------------
  // collision checkers: would the bitmap, placed at (cx,cy), overlap a wall,
  // the floor, or a locked cell?  One instance per move we may attempt.
  // -------------------------------------------------------------------------
  wire hit_l, hit_r, hit_d, hit_rot, hit_spawn;

  tetris_hitchk u_chk_l   (.bm(bm_cur),  .cx(posx - 6'd1), .cy(posy),        .fld(field_flat), .hit(hit_l));
  tetris_hitchk u_chk_r   (.bm(bm_cur),  .cx(posx + 6'd1), .cy(posy),        .fld(field_flat), .hit(hit_r));
  tetris_hitchk u_chk_d   (.bm(bm_cur),  .cx(posx),        .cy(posy + 6'd1), .fld(field_flat), .hit(hit_d));
  tetris_hitchk u_chk_rot (.bm(bm_rot),  .cx(posx),        .cy(posy),        .fld(field_flat), .hit(hit_rot));
  tetris_hitchk u_chk_sp  (.bm(bm_nxt0), .cx(6'd3),        .cy(6'd0),        .fld(field_flat), .hit(hit_spawn));

  // -------------------------------------------------------------------------
  // current-piece mask over the field: shared per-column / per-row relative
  // coordinates, then one AND per cell.  Used by ST_LOCK and the raster.
  // 6-bit two's-complement wraparound makes the < 4 window tests exact.
  // -------------------------------------------------------------------------
  wire [5:0]   relx [0:9];
  wire [5:0]   rely [0:19];
  wire [199:0] cur_mask_flat;

  genvar gx, gy;
  generate
    for (gx = 0; gx < 10; gx = gx + 1) begin : g_rx
      assign relx[gx] = gx - posx;
    end
    for (gy = 0; gy < 20; gy = gy + 1) begin : g_ry
      assign rely[gy] = gy - posy;
    end
    for (gy = 0; gy < 20; gy = gy + 1) begin : g_cm_y
      for (gx = 0; gx < 10; gx = gx + 1) begin : g_cm_x
        assign cur_mask_flat[(gy << 3) + (gy << 1) + gx] =
            (relx[gx] < 6'd4) && (rely[gy] < 6'd4) &&
            bm_cur[{rely[gy][1:0], relx[gx][1:0]}];
      end
    end
  endgenerate

  // -------------------------------------------------------------------------
  // main FSM
  // -------------------------------------------------------------------------
  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < 20; i = i + 1) frow[i] <= 10'd0;
      state    <= ST_NEW;
      cur_type <= 3'd0;
      nxt_type <= 3'd0;
      rot      <= 2'd0;
      posx     <= 6'd3;
      posy     <= 6'd0;
      lrow     <= 5'd0;
      lines    <= 8'd0;
      pieces   <= 8'd0;
      req_rot  <= 1'b0;
      req_l    <= 1'b0;
      req_r    <= 1'b0;
      req_drop <= 1'b0;
      grav_due <= 1'b0;
    end else if (en) begin
      if (p_new) begin
        for (i = 0; i < 20; i = i + 1) frow[i] <= 10'd0;
        state    <= ST_NEW;
        lines    <= 8'd0;
        pieces   <= 8'd0;
        req_rot  <= 1'b0;
        req_l    <= 1'b0;
        req_r    <= 1'b0;
        req_drop <= 1'b0;
        grav_due <= 1'b0;
      end else begin
        // sticky input requests, serviced one per clock by ST_FALL below.
        // A service-clear in the same cycle wins (later assignment).
        if (state == ST_FALL) begin
          if (p_left)    req_l    <= 1'b1;
          if (p_right)   req_r    <= 1'b1;
          if (p_rot)     req_rot  <= 1'b1;
          if (p_drop)    req_drop <= 1'b1;
          if (tick_grav) grav_due <= 1'b1;
        end

        case (state)
          ST_NEW: begin
            // reroll until the 3-bit draw lands on a valid type 0..6
            if (rnd[2:0] != 3'd7) begin
              nxt_type <= rnd[2:0];
              state    <= ST_SPAWN;
            end
          end

          ST_SPAWN: begin
            if (hit_spawn) begin
              state <= ST_OVER;
            end else begin
              cur_type <= nxt_type;
              rot      <= 2'd0;
              posx     <= 6'd3;
              posy     <= 6'd0;
              if (pieces != 8'hFF) pieces <= pieces + 8'd1;
              req_rot  <= 1'b0;
              req_l    <= 1'b0;
              req_r    <= 1'b0;
              req_drop <= 1'b0;
              grav_due <= 1'b0;
              state    <= ST_PICK;
            end
          end

          ST_PICK: begin
            if (rnd[2:0] != 3'd7) begin
              nxt_type <= rnd[2:0];
              state    <= ST_FALL;
            end
          end

          ST_FALL: begin
            if (req_rot) begin
              req_rot <= 1'b0;
              if (!hit_rot) rot <= rot + 2'd1;
            end else if (req_l) begin
              req_l <= 1'b0;
              if (!hit_l) posx <= posx - 6'd1;
            end else if (req_r) begin
              req_r <= 1'b0;
              if (!hit_r) posx <= posx + 6'd1;
            end else if (req_drop) begin
              req_drop <= 1'b0;
              state    <= ST_DROP;
            end else if (grav_due) begin
              grav_due <= 1'b0;
              if (hit_d) state <= ST_LOCK;
              else       posy  <= posy + 6'd1;
            end
          end

          ST_DROP: begin
            if (hit_d) state <= ST_LOCK;
            else       posy  <= posy + 6'd1;
          end

          ST_LOCK: begin
            // merge the piece into the field in one clock; rows the piece
            // does not touch OR in all-zero bits.
            for (i = 0; i < 20; i = i + 1)
              frow[i] <= frow[i] | cur_mask_flat[r10(i) +: 10];
            lrow  <= 5'd19;
            state <= ST_LINECHK;
          end

          ST_LINECHK: begin
            // bottom-up scan, one row per clock.  A full row pulls every row
            // above it down one step and is re-checked (the row that slid in
            // may itself be full).
            if (frow[lrow] == 10'h3FF) begin
              for (i = 1; i < 20; i = i + 1)
                if (i <= lrow) frow[i] <= frow[i - 1];
              frow[0] <= 10'd0;
              if (lines != 8'hFF) lines <= lines + 8'd1;
            end else if (lrow == 5'd0) begin
              state <= ST_SPAWN;
            end else begin
              lrow <= lrow - 5'd1;
            end
          end

          ST_OVER: begin
            // field blinks in the raster; wait for btn_new.
          end

          default: state <= ST_NEW;
        endcase
      end
    end
  end

  // -------------------------------------------------------------------------
  // raster: walls, locked field, falling piece.  In ST_OVER the field blinks.
  // -------------------------------------------------------------------------
  wire piece_vis = (state == ST_FALL) || (state == ST_DROP) || (state == ST_LOCK);
  wire [199:0] disp_flat = field_flat | ({200{piece_vis}} & cur_mask_flat);

  wire border = (r_x == 4'd0) || (r_x == 4'd11) || (r_y == 5'd21);
  wire infld  = (r_x >= 4'd1) && (r_x <= 4'd10) && (r_y >= 5'd1) && (r_y <= 5'd20);

  wire [3:0] fx = r_x - 4'd1;
  wire [4:0] fy = r_y - 5'd1;

  wire fshow  = (state != ST_OVER) || frame_cnt[3];
  wire cellpx = infld && fshow && disp_flat[r10({3'b000, fy}) + {4'b0000, fx}];

  wire pix = border | cellpx;

  // -------------------------------------------------------------------------
  // pixel bus + status outputs
  // -------------------------------------------------------------------------
  assign px_x     = r_x;
  assign px_y     = r_y;
  assign frame    = en & r_clear;
  assign px_clear = en & r_clear;
  assign px_fill  = 1'b0;
  assign px_en    = en & ~r_clear & pix;

  assign o_lines  = lines;
  assign o_pieces = pieces;
  assign o_next   = nxt_type;
  assign o_over   = (state == ST_OVER);

endmodule

// ----------------------------------------------------------------------------
// tetris_hitchk : collision test for a 4x4 piece bitmap placed at (cx,cy) on
// the 10x20 field (flat, bit = 10*y + x).  hit=1 if any set bitmap cell lands
// outside columns 0..9, below row 19, or on an occupied field cell.  Cells
// above row 0 (cy negative) are legal head-room.  All coordinates are 6-bit
// two's complement; the unsigned > tests catch the wrapped negatives.
// ----------------------------------------------------------------------------
module tetris_hitchk (
  input  wire [15:0]  bm,
  input  wire [5:0]   cx,
  input  wire [5:0]   cy,
  input  wire [199:0] fld,
  output wire         hit
);
  function [7:0] r10;
    input [7:0] r;
    begin
      r10 = {r[4:0], 3'b000} + {2'b00, r[4:0], 1'b0};
    end
  endfunction

  wire [15:0] hk;

  genvar k;
  generate
    for (k = 0; k < 16; k = k + 1) begin : g_cell
      wire [5:0] ax = cx + (k & 3);
      wire [5:0] ay = cy + (k >> 2);
      wire xbad  = (ax > 6'd9);
      wire ybad  = (~ay[5]) && (ay > 6'd19);
      wire infld = (~xbad) && (~ay[5]) && (ay <= 6'd19);
      wire occ   = fld[r10({2'b00, ay}) + {2'b00, ax}];
      assign hk[k] = bm[k] && (xbad || ybad || (infld && occ));
    end
  endgenerate

  assign hit = |hk;
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
