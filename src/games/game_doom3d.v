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
      8'h00: sinlut = 8'h00;  //    0
      8'h01: sinlut = 8'h02;  //    2
      8'h02: sinlut = 8'h03;  //    3
      8'h03: sinlut = 8'h05;  //    5
      8'h04: sinlut = 8'h06;  //    6
      8'h05: sinlut = 8'h08;  //    8
      8'h06: sinlut = 8'h09;  //    9
      8'h07: sinlut = 8'h0B;  //   11
      8'h08: sinlut = 8'h0C;  //   12
      8'h09: sinlut = 8'h0E;  //   14
      8'h0A: sinlut = 8'h10;  //   16
      8'h0B: sinlut = 8'h11;  //   17
      8'h0C: sinlut = 8'h13;  //   19
      8'h0D: sinlut = 8'h14;  //   20
      8'h0E: sinlut = 8'h16;  //   22
      8'h0F: sinlut = 8'h17;  //   23
      8'h10: sinlut = 8'h18;  //   24
      8'h11: sinlut = 8'h1A;  //   26
      8'h12: sinlut = 8'h1B;  //   27
      8'h13: sinlut = 8'h1D;  //   29
      8'h14: sinlut = 8'h1E;  //   30
      8'h15: sinlut = 8'h20;  //   32
      8'h16: sinlut = 8'h21;  //   33
      8'h17: sinlut = 8'h22;  //   34
      8'h18: sinlut = 8'h24;  //   36
      8'h19: sinlut = 8'h25;  //   37
      8'h1A: sinlut = 8'h26;  //   38
      8'h1B: sinlut = 8'h27;  //   39
      8'h1C: sinlut = 8'h29;  //   41
      8'h1D: sinlut = 8'h2A;  //   42
      8'h1E: sinlut = 8'h2B;  //   43
      8'h1F: sinlut = 8'h2C;  //   44
      8'h20: sinlut = 8'h2D;  //   45
      8'h21: sinlut = 8'h2E;  //   46
      8'h22: sinlut = 8'h2F;  //   47
      8'h23: sinlut = 8'h30;  //   48
      8'h24: sinlut = 8'h31;  //   49
      8'h25: sinlut = 8'h32;  //   50
      8'h26: sinlut = 8'h33;  //   51
      8'h27: sinlut = 8'h34;  //   52
      8'h28: sinlut = 8'h35;  //   53
      8'h29: sinlut = 8'h36;  //   54
      8'h2A: sinlut = 8'h37;  //   55
      8'h2B: sinlut = 8'h38;  //   56
      8'h2C: sinlut = 8'h38;  //   56
      8'h2D: sinlut = 8'h39;  //   57
      8'h2E: sinlut = 8'h3A;  //   58
      8'h2F: sinlut = 8'h3B;  //   59
      8'h30: sinlut = 8'h3B;  //   59
      8'h31: sinlut = 8'h3C;  //   60
      8'h32: sinlut = 8'h3C;  //   60
      8'h33: sinlut = 8'h3D;  //   61
      8'h34: sinlut = 8'h3D;  //   61
      8'h35: sinlut = 8'h3E;  //   62
      8'h36: sinlut = 8'h3E;  //   62
      8'h37: sinlut = 8'h3E;  //   62
      8'h38: sinlut = 8'h3F;  //   63
      8'h39: sinlut = 8'h3F;  //   63
      8'h3A: sinlut = 8'h3F;  //   63
      8'h3B: sinlut = 8'h40;  //   64
      8'h3C: sinlut = 8'h40;  //   64
      8'h3D: sinlut = 8'h40;  //   64
      8'h3E: sinlut = 8'h40;  //   64
      8'h3F: sinlut = 8'h40;  //   64
      8'h40: sinlut = 8'h40;  //   64
      8'h41: sinlut = 8'h40;  //   64
      8'h42: sinlut = 8'h40;  //   64
      8'h43: sinlut = 8'h40;  //   64
      8'h44: sinlut = 8'h40;  //   64
      8'h45: sinlut = 8'h40;  //   64
      8'h46: sinlut = 8'h3F;  //   63
      8'h47: sinlut = 8'h3F;  //   63
      8'h48: sinlut = 8'h3F;  //   63
      8'h49: sinlut = 8'h3E;  //   62
      8'h4A: sinlut = 8'h3E;  //   62
      8'h4B: sinlut = 8'h3E;  //   62
      8'h4C: sinlut = 8'h3D;  //   61
      8'h4D: sinlut = 8'h3D;  //   61
      8'h4E: sinlut = 8'h3C;  //   60
      8'h4F: sinlut = 8'h3C;  //   60
      8'h50: sinlut = 8'h3B;  //   59
      8'h51: sinlut = 8'h3B;  //   59
      8'h52: sinlut = 8'h3A;  //   58
      8'h53: sinlut = 8'h39;  //   57
      8'h54: sinlut = 8'h38;  //   56
      8'h55: sinlut = 8'h38;  //   56
      8'h56: sinlut = 8'h37;  //   55
      8'h57: sinlut = 8'h36;  //   54
      8'h58: sinlut = 8'h35;  //   53
      8'h59: sinlut = 8'h34;  //   52
      8'h5A: sinlut = 8'h33;  //   51
      8'h5B: sinlut = 8'h32;  //   50
      8'h5C: sinlut = 8'h31;  //   49
      8'h5D: sinlut = 8'h30;  //   48
      8'h5E: sinlut = 8'h2F;  //   47
      8'h5F: sinlut = 8'h2E;  //   46
      8'h60: sinlut = 8'h2D;  //   45
      8'h61: sinlut = 8'h2C;  //   44
      8'h62: sinlut = 8'h2B;  //   43
      8'h63: sinlut = 8'h2A;  //   42
      8'h64: sinlut = 8'h29;  //   41
      8'h65: sinlut = 8'h27;  //   39
      8'h66: sinlut = 8'h26;  //   38
      8'h67: sinlut = 8'h25;  //   37
      8'h68: sinlut = 8'h24;  //   36
      8'h69: sinlut = 8'h22;  //   34
      8'h6A: sinlut = 8'h21;  //   33
      8'h6B: sinlut = 8'h20;  //   32
      8'h6C: sinlut = 8'h1E;  //   30
      8'h6D: sinlut = 8'h1D;  //   29
      8'h6E: sinlut = 8'h1B;  //   27
      8'h6F: sinlut = 8'h1A;  //   26
      8'h70: sinlut = 8'h18;  //   24
      8'h71: sinlut = 8'h17;  //   23
      8'h72: sinlut = 8'h16;  //   22
      8'h73: sinlut = 8'h14;  //   20
      8'h74: sinlut = 8'h13;  //   19
      8'h75: sinlut = 8'h11;  //   17
      8'h76: sinlut = 8'h10;  //   16
      8'h77: sinlut = 8'h0E;  //   14
      8'h78: sinlut = 8'h0C;  //   12
      8'h79: sinlut = 8'h0B;  //   11
      8'h7A: sinlut = 8'h09;  //    9
      8'h7B: sinlut = 8'h08;  //    8
      8'h7C: sinlut = 8'h06;  //    6
      8'h7D: sinlut = 8'h05;  //    5
      8'h7E: sinlut = 8'h03;  //    3
      8'h7F: sinlut = 8'h02;  //    2
      8'h80: sinlut = 8'h00;  //    0
      8'h81: sinlut = 8'hFE;  //   -2
      8'h82: sinlut = 8'hFD;  //   -3
      8'h83: sinlut = 8'hFB;  //   -5
      8'h84: sinlut = 8'hFA;  //   -6
      8'h85: sinlut = 8'hF8;  //   -8
      8'h86: sinlut = 8'hF7;  //   -9
      8'h87: sinlut = 8'hF5;  //  -11
      8'h88: sinlut = 8'hF4;  //  -12
      8'h89: sinlut = 8'hF2;  //  -14
      8'h8A: sinlut = 8'hF0;  //  -16
      8'h8B: sinlut = 8'hEF;  //  -17
      8'h8C: sinlut = 8'hED;  //  -19
      8'h8D: sinlut = 8'hEC;  //  -20
      8'h8E: sinlut = 8'hEA;  //  -22
      8'h8F: sinlut = 8'hE9;  //  -23
      8'h90: sinlut = 8'hE8;  //  -24
      8'h91: sinlut = 8'hE6;  //  -26
      8'h92: sinlut = 8'hE5;  //  -27
      8'h93: sinlut = 8'hE3;  //  -29
      8'h94: sinlut = 8'hE2;  //  -30
      8'h95: sinlut = 8'hE0;  //  -32
      8'h96: sinlut = 8'hDF;  //  -33
      8'h97: sinlut = 8'hDE;  //  -34
      8'h98: sinlut = 8'hDC;  //  -36
      8'h99: sinlut = 8'hDB;  //  -37
      8'h9A: sinlut = 8'hDA;  //  -38
      8'h9B: sinlut = 8'hD9;  //  -39
      8'h9C: sinlut = 8'hD7;  //  -41
      8'h9D: sinlut = 8'hD6;  //  -42
      8'h9E: sinlut = 8'hD5;  //  -43
      8'h9F: sinlut = 8'hD4;  //  -44
      8'hA0: sinlut = 8'hD3;  //  -45
      8'hA1: sinlut = 8'hD2;  //  -46
      8'hA2: sinlut = 8'hD1;  //  -47
      8'hA3: sinlut = 8'hD0;  //  -48
      8'hA4: sinlut = 8'hCF;  //  -49
      8'hA5: sinlut = 8'hCE;  //  -50
      8'hA6: sinlut = 8'hCD;  //  -51
      8'hA7: sinlut = 8'hCC;  //  -52
      8'hA8: sinlut = 8'hCB;  //  -53
      8'hA9: sinlut = 8'hCA;  //  -54
      8'hAA: sinlut = 8'hC9;  //  -55
      8'hAB: sinlut = 8'hC8;  //  -56
      8'hAC: sinlut = 8'hC8;  //  -56
      8'hAD: sinlut = 8'hC7;  //  -57
      8'hAE: sinlut = 8'hC6;  //  -58
      8'hAF: sinlut = 8'hC5;  //  -59
      8'hB0: sinlut = 8'hC5;  //  -59
      8'hB1: sinlut = 8'hC4;  //  -60
      8'hB2: sinlut = 8'hC4;  //  -60
      8'hB3: sinlut = 8'hC3;  //  -61
      8'hB4: sinlut = 8'hC3;  //  -61
      8'hB5: sinlut = 8'hC2;  //  -62
      8'hB6: sinlut = 8'hC2;  //  -62
      8'hB7: sinlut = 8'hC2;  //  -62
      8'hB8: sinlut = 8'hC1;  //  -63
      8'hB9: sinlut = 8'hC1;  //  -63
      8'hBA: sinlut = 8'hC1;  //  -63
      8'hBB: sinlut = 8'hC0;  //  -64
      8'hBC: sinlut = 8'hC0;  //  -64
      8'hBD: sinlut = 8'hC0;  //  -64
      8'hBE: sinlut = 8'hC0;  //  -64
      8'hBF: sinlut = 8'hC0;  //  -64
      8'hC0: sinlut = 8'hC0;  //  -64
      8'hC1: sinlut = 8'hC0;  //  -64
      8'hC2: sinlut = 8'hC0;  //  -64
      8'hC3: sinlut = 8'hC0;  //  -64
      8'hC4: sinlut = 8'hC0;  //  -64
      8'hC5: sinlut = 8'hC0;  //  -64
      8'hC6: sinlut = 8'hC1;  //  -63
      8'hC7: sinlut = 8'hC1;  //  -63
      8'hC8: sinlut = 8'hC1;  //  -63
      8'hC9: sinlut = 8'hC2;  //  -62
      8'hCA: sinlut = 8'hC2;  //  -62
      8'hCB: sinlut = 8'hC2;  //  -62
      8'hCC: sinlut = 8'hC3;  //  -61
      8'hCD: sinlut = 8'hC3;  //  -61
      8'hCE: sinlut = 8'hC4;  //  -60
      8'hCF: sinlut = 8'hC4;  //  -60
      8'hD0: sinlut = 8'hC5;  //  -59
      8'hD1: sinlut = 8'hC5;  //  -59
      8'hD2: sinlut = 8'hC6;  //  -58
      8'hD3: sinlut = 8'hC7;  //  -57
      8'hD4: sinlut = 8'hC8;  //  -56
      8'hD5: sinlut = 8'hC8;  //  -56
      8'hD6: sinlut = 8'hC9;  //  -55
      8'hD7: sinlut = 8'hCA;  //  -54
      8'hD8: sinlut = 8'hCB;  //  -53
      8'hD9: sinlut = 8'hCC;  //  -52
      8'hDA: sinlut = 8'hCD;  //  -51
      8'hDB: sinlut = 8'hCE;  //  -50
      8'hDC: sinlut = 8'hCF;  //  -49
      8'hDD: sinlut = 8'hD0;  //  -48
      8'hDE: sinlut = 8'hD1;  //  -47
      8'hDF: sinlut = 8'hD2;  //  -46
      8'hE0: sinlut = 8'hD3;  //  -45
      8'hE1: sinlut = 8'hD4;  //  -44
      8'hE2: sinlut = 8'hD5;  //  -43
      8'hE3: sinlut = 8'hD6;  //  -42
      8'hE4: sinlut = 8'hD7;  //  -41
      8'hE5: sinlut = 8'hD9;  //  -39
      8'hE6: sinlut = 8'hDA;  //  -38
      8'hE7: sinlut = 8'hDB;  //  -37
      8'hE8: sinlut = 8'hDC;  //  -36
      8'hE9: sinlut = 8'hDE;  //  -34
      8'hEA: sinlut = 8'hDF;  //  -33
      8'hEB: sinlut = 8'hE0;  //  -32
      8'hEC: sinlut = 8'hE2;  //  -30
      8'hED: sinlut = 8'hE3;  //  -29
      8'hEE: sinlut = 8'hE5;  //  -27
      8'hEF: sinlut = 8'hE6;  //  -26
      8'hF0: sinlut = 8'hE8;  //  -24
      8'hF1: sinlut = 8'hE9;  //  -23
      8'hF2: sinlut = 8'hEA;  //  -22
      8'hF3: sinlut = 8'hEC;  //  -20
      8'hF4: sinlut = 8'hED;  //  -19
      8'hF5: sinlut = 8'hEF;  //  -17
      8'hF6: sinlut = 8'hF0;  //  -16
      8'hF7: sinlut = 8'hF2;  //  -14
      8'hF8: sinlut = 8'hF4;  //  -12
      8'hF9: sinlut = 8'hF5;  //  -11
      8'hFA: sinlut = 8'hF7;  //   -9
      8'hFB: sinlut = 8'hF8;  //   -8
      8'hFC: sinlut = 8'hFA;  //   -6
      8'hFD: sinlut = 8'hFB;  //   -5
      8'hFE: sinlut = 8'hFD;  //   -3
      8'hFF: sinlut = 8'hFE;  //   -2
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
      5'h00: colofs = 8'hEB;  // -21
      5'h01: colofs = 8'hED;  // -19
      5'h02: colofs = 8'hEE;  // -18
      5'h03: colofs = 8'hEF;  // -17
      5'h04: colofs = 8'hF1;  // -15
      5'h05: colofs = 8'hF2;  // -14
      5'h06: colofs = 8'hF3;  // -13
      5'h07: colofs = 8'hF5;  // -11
      5'h08: colofs = 8'hF6;  // -10
      5'h09: colofs = 8'hF7;  //  -9
      5'h0A: colofs = 8'hF9;  //  -7
      5'h0B: colofs = 8'hFA;  //  -6
      5'h0C: colofs = 8'hFB;  //  -5
      5'h0D: colofs = 8'hFD;  //  -3
      5'h0E: colofs = 8'hFE;  //  -2
      5'h0F: colofs = 8'hFF;  //  -1
      5'h10: colofs = 8'h01;  //   1
      5'h11: colofs = 8'h02;  //   2
      5'h12: colofs = 8'h03;  //   3
      5'h13: colofs = 8'h05;  //   5
      5'h14: colofs = 8'h06;  //   6
      5'h15: colofs = 8'h07;  //   7
      5'h16: colofs = 8'h09;  //   9
      5'h17: colofs = 8'h0A;  //  10
      5'h18: colofs = 8'h0B;  //  11
      5'h19: colofs = 8'h0D;  //  13
      5'h1A: colofs = 8'h0E;  //  14
      5'h1B: colofs = 8'h0F;  //  15
      5'h1C: colofs = 8'h11;  //  17
      5'h1D: colofs = 8'h12;  //  18
      5'h1E: colofs = 8'h13;  //  19
      5'h1F: colofs = 8'h15;  //  21
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
      8'h00: hgt = 4'd15;
      8'h01: hgt = 4'd15;
      8'h02: hgt = 4'd15;
      8'h03: hgt = 4'd15;
      8'h04: hgt = 4'd15;
      8'h05: hgt = 4'd15;
      8'h06: hgt = 4'd15;
      8'h07: hgt = 4'd15;
      8'h08: hgt = 4'd14;
      8'h09: hgt = 4'd12;
      8'h0A: hgt = 4'd11;
      8'h0B: hgt = 4'd10;
      8'h0C: hgt = 4'd9;
      8'h0D: hgt = 4'd9;
      8'h0E: hgt = 4'd8;
      8'h0F: hgt = 4'd7;
      8'h10: hgt = 4'd7;
      8'h11: hgt = 4'd7;
      8'h12: hgt = 4'd6;
      8'h13: hgt = 4'd6;
      8'h14: hgt = 4'd6;
      8'h15: hgt = 4'd5;
      8'h16: hgt = 4'd5;
      8'h17: hgt = 4'd5;
      8'h18: hgt = 4'd5;
      8'h19: hgt = 4'd4;
      8'h1A: hgt = 4'd4;
      8'h1B: hgt = 4'd4;
      8'h1C: hgt = 4'd4;
      8'h1D: hgt = 4'd4;
      8'h1E: hgt = 4'd4;
      8'h1F: hgt = 4'd4;
      8'h20: hgt = 4'd4;
      8'h21: hgt = 4'd3;
      8'h22: hgt = 4'd3;
      8'h23: hgt = 4'd3;
      8'h24: hgt = 4'd3;
      8'h25: hgt = 4'd3;
      8'h26: hgt = 4'd3;
      8'h27: hgt = 4'd3;
      8'h28: hgt = 4'd3;
      8'h29: hgt = 4'd3;
      8'h2A: hgt = 4'd3;
      8'h2B: hgt = 4'd3;
      8'h2C: hgt = 4'd3;
      8'h2D: hgt = 4'd2;
      8'h2E: hgt = 4'd2;
      8'h2F: hgt = 4'd2;
      8'h30: hgt = 4'd2;
      8'h31: hgt = 4'd2;
      8'h32: hgt = 4'd2;
      8'h33: hgt = 4'd2;
      8'h34: hgt = 4'd2;
      8'h35: hgt = 4'd2;
      8'h36: hgt = 4'd2;
      8'h37: hgt = 4'd2;
      8'h38: hgt = 4'd2;
      8'h39: hgt = 4'd2;
      8'h3A: hgt = 4'd2;
      8'h3B: hgt = 4'd2;
      8'h3C: hgt = 4'd2;
      8'h3D: hgt = 4'd2;
      8'h3E: hgt = 4'd2;
      8'h3F: hgt = 4'd2;
      8'h40: hgt = 4'd2;
      8'h41: hgt = 4'd2;
      8'h42: hgt = 4'd2;
      8'h43: hgt = 4'd2;
      8'h44: hgt = 4'd2;
      8'h45: hgt = 4'd2;
      8'h46: hgt = 4'd2;
      8'h47: hgt = 4'd2;
      8'h48: hgt = 4'd2;
      8'h49: hgt = 4'd2;
      8'h4A: hgt = 4'd2;
      8'h4B: hgt = 4'd1;
      8'h4C: hgt = 4'd1;
      8'h4D: hgt = 4'd1;
      8'h4E: hgt = 4'd1;
      8'h4F: hgt = 4'd1;
      8'h50: hgt = 4'd1;
      8'h51: hgt = 4'd1;
      8'h52: hgt = 4'd1;
      8'h53: hgt = 4'd1;
      8'h54: hgt = 4'd1;
      8'h55: hgt = 4'd1;
      8'h56: hgt = 4'd1;
      8'h57: hgt = 4'd1;
      8'h58: hgt = 4'd1;
      8'h59: hgt = 4'd1;
      8'h5A: hgt = 4'd1;
      8'h5B: hgt = 4'd1;
      8'h5C: hgt = 4'd1;
      8'h5D: hgt = 4'd1;
      8'h5E: hgt = 4'd1;
      8'h5F: hgt = 4'd1;
      8'h60: hgt = 4'd1;
      8'h61: hgt = 4'd1;
      8'h62: hgt = 4'd1;
      8'h63: hgt = 4'd1;
      8'h64: hgt = 4'd1;
      8'h65: hgt = 4'd1;
      8'h66: hgt = 4'd1;
      8'h67: hgt = 4'd1;
      8'h68: hgt = 4'd1;
      8'h69: hgt = 4'd1;
      8'h6A: hgt = 4'd1;
      8'h6B: hgt = 4'd1;
      8'h6C: hgt = 4'd1;
      8'h6D: hgt = 4'd1;
      8'h6E: hgt = 4'd1;
      8'h6F: hgt = 4'd1;
      8'h70: hgt = 4'd1;
      8'h71: hgt = 4'd1;
      8'h72: hgt = 4'd1;
      8'h73: hgt = 4'd1;
      8'h74: hgt = 4'd1;
      8'h75: hgt = 4'd1;
      8'h76: hgt = 4'd1;
      8'h77: hgt = 4'd1;
      8'h78: hgt = 4'd1;
      8'h79: hgt = 4'd1;
      8'h7A: hgt = 4'd1;
      8'h7B: hgt = 4'd1;
      8'h7C: hgt = 4'd1;
      8'h7D: hgt = 4'd1;
      8'h7E: hgt = 4'd1;
      8'h7F: hgt = 4'd1;
      8'h80: hgt = 4'd1;
      8'h81: hgt = 4'd1;
      8'h82: hgt = 4'd1;
      8'h83: hgt = 4'd1;
      8'h84: hgt = 4'd1;
      8'h85: hgt = 4'd1;
      8'h86: hgt = 4'd1;
      8'h87: hgt = 4'd1;
      8'h88: hgt = 4'd1;
      8'h89: hgt = 4'd1;
      8'h8A: hgt = 4'd1;
      8'h8B: hgt = 4'd1;
      8'h8C: hgt = 4'd1;
      8'h8D: hgt = 4'd1;
      8'h8E: hgt = 4'd1;
      8'h8F: hgt = 4'd1;
      8'h90: hgt = 4'd1;
      8'h91: hgt = 4'd1;
      8'h92: hgt = 4'd1;
      8'h93: hgt = 4'd1;
      8'h94: hgt = 4'd1;
      8'h95: hgt = 4'd1;
      8'h96: hgt = 4'd1;
      8'h97: hgt = 4'd1;
      8'h98: hgt = 4'd1;
      8'h99: hgt = 4'd1;
      8'h9A: hgt = 4'd1;
      8'h9B: hgt = 4'd1;
      8'h9C: hgt = 4'd1;
      8'h9D: hgt = 4'd1;
      8'h9E: hgt = 4'd1;
      8'h9F: hgt = 4'd1;
      8'hA0: hgt = 4'd1;
      8'hA1: hgt = 4'd1;
      8'hA2: hgt = 4'd1;
      8'hA3: hgt = 4'd1;
      8'hA4: hgt = 4'd1;
      8'hA5: hgt = 4'd1;
      8'hA6: hgt = 4'd1;
      8'hA7: hgt = 4'd1;
      8'hA8: hgt = 4'd1;
      8'hA9: hgt = 4'd1;
      8'hAA: hgt = 4'd1;
      8'hAB: hgt = 4'd1;
      8'hAC: hgt = 4'd1;
      8'hAD: hgt = 4'd1;
      8'hAE: hgt = 4'd1;
      8'hAF: hgt = 4'd1;
      8'hB0: hgt = 4'd1;
      8'hB1: hgt = 4'd1;
      8'hB2: hgt = 4'd1;
      8'hB3: hgt = 4'd1;
      8'hB4: hgt = 4'd1;
      8'hB5: hgt = 4'd1;
      8'hB6: hgt = 4'd1;
      8'hB7: hgt = 4'd1;
      8'hB8: hgt = 4'd1;
      8'hB9: hgt = 4'd1;
      8'hBA: hgt = 4'd1;
      8'hBB: hgt = 4'd1;
      8'hBC: hgt = 4'd1;
      8'hBD: hgt = 4'd1;
      8'hBE: hgt = 4'd1;
      8'hBF: hgt = 4'd1;
      8'hC0: hgt = 4'd1;
      8'hC1: hgt = 4'd1;
      8'hC2: hgt = 4'd1;
      8'hC3: hgt = 4'd1;
      8'hC4: hgt = 4'd1;
      8'hC5: hgt = 4'd1;
      8'hC6: hgt = 4'd1;
      8'hC7: hgt = 4'd1;
      8'hC8: hgt = 4'd1;
      8'hC9: hgt = 4'd1;
      8'hCA: hgt = 4'd1;
      8'hCB: hgt = 4'd1;
      8'hCC: hgt = 4'd1;
      8'hCD: hgt = 4'd1;
      8'hCE: hgt = 4'd1;
      8'hCF: hgt = 4'd1;
      8'hD0: hgt = 4'd1;
      8'hD1: hgt = 4'd1;
      8'hD2: hgt = 4'd1;
      8'hD3: hgt = 4'd1;
      8'hD4: hgt = 4'd1;
      8'hD5: hgt = 4'd1;
      8'hD6: hgt = 4'd1;
      8'hD7: hgt = 4'd1;
      8'hD8: hgt = 4'd1;
      8'hD9: hgt = 4'd1;
      8'hDA: hgt = 4'd1;
      8'hDB: hgt = 4'd1;
      8'hDC: hgt = 4'd1;
      8'hDD: hgt = 4'd1;
      8'hDE: hgt = 4'd1;
      8'hDF: hgt = 4'd1;
      8'hE0: hgt = 4'd1;
      8'hE1: hgt = 4'd1;
      8'hE2: hgt = 4'd1;
      8'hE3: hgt = 4'd1;
      8'hE4: hgt = 4'd1;
      8'hE5: hgt = 4'd1;
      8'hE6: hgt = 4'd1;
      8'hE7: hgt = 4'd1;
      8'hE8: hgt = 4'd1;
      8'hE9: hgt = 4'd1;
      8'hEA: hgt = 4'd1;
      8'hEB: hgt = 4'd1;
      8'hEC: hgt = 4'd1;
      8'hED: hgt = 4'd1;
      8'hEE: hgt = 4'd1;
      8'hEF: hgt = 4'd1;
      8'hF0: hgt = 4'd1;
      8'hF1: hgt = 4'd1;
      8'hF2: hgt = 4'd1;
      8'hF3: hgt = 4'd1;
      8'hF4: hgt = 4'd1;
      8'hF5: hgt = 4'd1;
      8'hF6: hgt = 4'd1;
      8'hF7: hgt = 4'd1;
      8'hF8: hgt = 4'd1;
      8'hF9: hgt = 4'd1;
      8'hFA: hgt = 4'd1;
      8'hFB: hgt = 4'd1;
      8'hFC: hgt = 4'd1;
      8'hFD: hgt = 4'd1;
      8'hFE: hgt = 4'd1;
      8'hFF: hgt = 4'd1;
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
      4'd0 : maprow = 16'b1111111111111111;
      4'd1 : maprow = 16'b1000000010000001;
      4'd2 : maprow = 16'b1011111010100001;
      4'd3 : maprow = 16'b1010000010111001;
      4'd4 : maprow = 16'b1010111110001001;
      4'd5 : maprow = 16'b1010100000101001;
      4'd6 : maprow = 16'b1010101111100001;
      4'd7 : maprow = 16'b1000101000101111;
      4'd8 : maprow = 16'b1011101010100001;
      4'd9 : maprow = 16'b1010001010111101;
      4'd10: maprow = 16'b1010111010000001;
      4'd11: maprow = 16'b1010100011111101;
      4'd12: maprow = 16'b1010101000000001;
      4'd13: maprow = 16'b1000001011111101;
      4'd14: maprow = 16'b1000001000000001;
      4'd15: maprow = 16'b1111111111111111;
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
