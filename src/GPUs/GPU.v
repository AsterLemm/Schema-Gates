// ============================================================================
//  GPU ,  IMMEDIATE-MODE RASTER / 2D-3D GRAPHICS PROCESSOR
//  BABFT FULL RV32I+M  /  BITFries-RV32IM  display subsystem
//  (C) 2026 BITFries / Glad-Note2022
//
//  No frame buffer. The GPU keeps only a small bounded SCENE STORE (a handful
//  of primitives, each a short vertex list + flags + colour) and a single
//  monochrome row register. Every pixel / row is RECOMPUTED on the fly from the
//  scene and streamed to the screen ("racing the beam"), so the cost is logic,
//  not RAM.
//
//  MODULAR (DigitalJS-style hierarchy): GPU_sin (x6), GPU_cfgdec,
//  GPU_slot_cov (x4), GPU_compose are drillable submodules; the shared-
//  multiplier transform/edge FSM stays in the top (it time-multiplexes
//  4 multipliers across all stages by design).
//  ---------------------------------------------------------------------------
//  CPU INTERFACE (memory-mapped slave, driven by Memory_And_MMIO):
//     gpu_we / gpu_addr[3:0] / gpu_wdata[31:0]  -> register writes
//     gpu_rdata[31:0]                           -> status read
//
//  REGISTER MAP (gpu_addr):
//   0  CONFIG     {  -, proj, ctype[1:0], h_field[7:0], w_field[7:0] }
//                 actual_w = w_field+1 (1..256), actual_h = h_field+1 (1..256)
//                 ctype: 00 mono | 01 MUX(4b idx) | 10 RGB12(4b/ch) | 11 RGB24(8b/ch)
//                 proj : 0 ortho | 1 isometric (locked 2:1)        [used for 3D]
//   1  CONTROL    { continuous, wait_for_screen, scene_clear*, commit*,
//                   fill, enable }            (* = self-clearing strobe)
//   2  ROT        { -, az[7:0], ay[7:0], ax[7:0] }   3D rotation, 0..255 = 0..360
//   3  FILLCOLOR  { rgb24 / low4 = mux idx }   colour used by the FILL command
//   4  SEL        { vert_ptr[3:0], slot[3:0] }  selects target slot + vertex ptr
//   5  PRIMHDR    { vcount[3:0], en, fill, is3d, type[1:0] }  -> slot=SEL.slot
//                 type: 00 point | 01 line | 10 polygon (tri/quad/convex n-gon)
//                 fill: polygon only (1 filled, 0 outline/wireframe)
//   6  PRIMCOL    { rgb24 / low4 = mux idx }   colour of slot=SEL.slot
//   7  VERT       { -, z[9:0], y[9:0], x[9:0] } signed; writes vertex at
//                 (SEL.slot, SEL.vert_ptr); vert_ptr auto-increments.
//                 2D prims: x,y are screen coords. 3D prims: x,y,z model space
//                 (centred on 0), rotated then projected and centred on screen.
//   8  read -> STATUS { ..., frame_done, busy }
//
//  Typical CPU flow: write CONFIG; for each shape -> SEL(slot,0), PRIMHDR,
//  PRIMCOL, VERT x N; then CONTROL.commit=1. For animation, update ROT and
//  re-commit each frame (or set CONTROL.continuous=1 to auto re-render).
//
//  ---------------------------------------------------------------------------
//  SCREEN INTERFACE (outputs):
//   scr_w/scr_h/scr_ctype : geometry + colour mode echoed to the display
//   enable                : display only draws while high
//   fill                  : flood the whole screen with FILLCOLOR
//   MONOCHROME (ctype=00, up to 256x256, row-parallel):
//     mono_valid, mono_y[7:0]  + row bitmap on FOUR 64-bit slices
//     mono_s0..mono_s3  (s0 = pixels 0..63 ... s3 = 192..255; low bits used
//     first for narrow screens). One row presented per handshake.
//   COLOUR (ctype=01/10/11, up to 32x32, pixel-serial):
//     px_valid, px_x[4:0], px_y[4:0], px_mux[3:0] (MUX), px_rgb[23:0] (RGB).
//     One pixel presented per handshake (RGB12 nibble-expanded into px_rgb).
//   HANDSHAKE: screen_ready advances the scan when CONTROL.wait_for_screen=1;
//     otherwise the GPU free-runs (one step/clock) and you slow the clock.
//     frame_start / frame_done pulse at the scan boundaries.
// ============================================================================

// ===========================================================================
//  GPU submodules (DigitalJS-style drillable hierarchy)
//  Every expression below is carried over verbatim from the previous
//  monolithic body; only the module boundaries are new.
// ===========================================================================

// --- GPU_sin : Q1.8 sine LUT (256 = 1.0) -- one instance per trig value ---
module GPU_sin(
    input  wire [7:0]         a,
    output reg signed [10:0]  s
);
    reg [1:0] q; reg [5:0] p; reg [6:0] idx; reg neg; reg signed [10:0] m;
    always @(*) begin
        q = a[7:6]; p = a[5:0];
        case (q)
            2'd0: begin idx = {1'b0,p};        neg = 1'b0; end
            2'd1: begin idx = 7'd64-{1'b0,p};  neg = 1'b0; end
            2'd2: begin idx = {1'b0,p};        neg = 1'b1; end
            default: begin idx = 7'd64-{1'b0,p}; neg = 1'b1; end
        endcase
        case (idx)
    7'd0: m = 11'sd0;
    7'd1: m = 11'sd6;
    7'd2: m = 11'sd13;
    7'd3: m = 11'sd19;
    7'd4: m = 11'sd25;
    7'd5: m = 11'sd31;
    7'd6: m = 11'sd38;
    7'd7: m = 11'sd44;
    7'd8: m = 11'sd50;
    7'd9: m = 11'sd56;
    7'd10: m = 11'sd62;
    7'd11: m = 11'sd68;
    7'd12: m = 11'sd74;
    7'd13: m = 11'sd80;
    7'd14: m = 11'sd86;
    7'd15: m = 11'sd92;
    7'd16: m = 11'sd98;
    7'd17: m = 11'sd104;
    7'd18: m = 11'sd109;
    7'd19: m = 11'sd115;
    7'd20: m = 11'sd121;
    7'd21: m = 11'sd126;
    7'd22: m = 11'sd132;
    7'd23: m = 11'sd137;
    7'd24: m = 11'sd142;
    7'd25: m = 11'sd147;
    7'd26: m = 11'sd152;
    7'd27: m = 11'sd157;
    7'd28: m = 11'sd162;
    7'd29: m = 11'sd167;
    7'd30: m = 11'sd172;
    7'd31: m = 11'sd177;
    7'd32: m = 11'sd181;
    7'd33: m = 11'sd185;
    7'd34: m = 11'sd190;
    7'd35: m = 11'sd194;
    7'd36: m = 11'sd198;
    7'd37: m = 11'sd202;
    7'd38: m = 11'sd206;
    7'd39: m = 11'sd209;
    7'd40: m = 11'sd213;
    7'd41: m = 11'sd216;
    7'd42: m = 11'sd220;
    7'd43: m = 11'sd223;
    7'd44: m = 11'sd226;
    7'd45: m = 11'sd229;
    7'd46: m = 11'sd231;
    7'd47: m = 11'sd234;
    7'd48: m = 11'sd237;
    7'd49: m = 11'sd239;
    7'd50: m = 11'sd241;
    7'd51: m = 11'sd243;
    7'd52: m = 11'sd245;
    7'd53: m = 11'sd247;
    7'd54: m = 11'sd248;
    7'd55: m = 11'sd250;
    7'd56: m = 11'sd251;
    7'd57: m = 11'sd252;
    7'd58: m = 11'sd253;
    7'd59: m = 11'sd254;
    7'd60: m = 11'sd255;
    7'd61: m = 11'sd255;
    7'd62: m = 11'sd256;
    7'd63: m = 11'sd256;
    7'd64: m = 11'sd256;
            default: m = 11'sd0;
        endcase
        s = neg ? -m : m;
    end
endmodule

// --- GPU_cfgdec : CONFIG decode (resolution clamp, mode one-hots) ---
// One-hot decode of the colour-type field. Each mode line is broadcast as
// an AND mask onto the operands of that mode's datapath, so only the
// selected colour pipeline ever toggles (the others stay frozen at 0).
// Same idea as the ALU's sel_* lines, applied to the GPU config.
module GPU_cfgdec(
    input  wire [7:0]  cfg_w,
    input  wire [7:0]  cfg_h,
    input  wire [1:0]  cfg_ctype,
    input  wire        cfg_proj,
    output wire [8:0]  res_w,
    output wire [8:0]  res_h,
    output wire        is_mono,
    output wire signed [11:0] cx,
    output wire signed [11:0] cy,
    output wire        mode_mono,
    output wire        mode_mux,
    output wire        mode_rgb12,
    output wire        mode_rgb24,
    output wire        mode_rgb,
    output wire        proj_iso,
    output wire        proj_ortho
);
    // active resolution (color modes clamp to 32x32)
    wire [8:0] res_w_full = {1'b0,cfg_w} + 9'd1;          // 1..256
    wire [8:0] res_h_full = {1'b0,cfg_h} + 9'd1;
    assign is_mono    = (cfg_ctype == 2'b00);
    assign res_w      = is_mono ? res_w_full : (res_w_full > 9'd32 ? 9'd32 : res_w_full);
    assign res_h      = is_mono ? res_h_full : (res_h_full > 9'd32 ? 9'd32 : res_h_full);
    assign cx = $signed({1'b0,res_w[8:1]});  // screen centre x (W/2)
    assign cy = $signed({1'b0,res_h[8:1]});  // screen centre y (H/2)

    assign mode_mono  = (cfg_ctype == 2'b00);
    assign mode_mux   = (cfg_ctype == 2'b01);
    assign mode_rgb12 = (cfg_ctype == 2'b10);
    assign mode_rgb24 = (cfg_ctype == 2'b11);
    assign mode_rgb   = mode_rgb12 | mode_rgb24;     // either RGB depth
    assign proj_iso   = cfg_proj;                    // isometric  skew active
    assign proj_ortho = ~cfg_proj;                   // orthographic (no skew)
endmodule

// --- GPU_slot_cov : per-pixel coverage for ONE primitive slot ---
// Same evaluator as the old in-line loop: edge sign accumulation for
// filled polygons, near-edge test for outlines/lines, exact match for
// points. pixel_en is the PROCESS GATE; en is the slot's OPERAND gate.
module GPU_slot_cov(
    input  wire                 pixel_en,
    input  wire                 en,
    input  wire [1:0]           ptype,
    input  wire                 pfill,
    input  wire [3:0]           pvcnt,
    input  wire [8:0]           cur_x,
    input  wire [8:0]           cur_y,
    input  wire signed [11:0]   px2b,     // projected base vertex (points)
    input  wire signed [11:0]   py2b,
    input  wire [8*32-1:0]      eE_flat,  // this slot's 8 edge accumulators
    input  wire [8*32-1:0]      edot_flat,
    input  wire [8*32-1:0]      eseg2_flat,
    input  wire [8*13-1:0]      emab_flat,
    output wire                 cov
);
    localparam CW = 12;
    localparam EW = 32;
    localparam T_POINT = 2'd0, T_LINE = 2'd1, T_POLY = 2'd2;

    reg allpos, allneg, onedge;
    reg covered;
    integer k;
    reg signed [EW-1:0] Ev, av, dv, sg;
    reg signed [CW:0]   mb;

    always @(*) begin
        allpos = 1'b1; allneg = 1'b1; onedge = 1'b0;
        covered = 1'b0;
        // PROCESS GATE + OPERAND ISOLATION: frozen unless a pixel is being
        // produced AND this slot is enabled (exactly as before).
        if (pixel_en && en) begin
            for (k = 0; k < 8; k = k + 1) begin
                if (k < pvcnt) begin
                    Ev = eE_flat[k*EW +: EW];
                    mb = emab_flat[k*13 +: 13];
                    dv = edot_flat[k*EW +: EW];
                    sg = eseg2_flat[k*EW +: EW];
                    av = (Ev[EW-1]) ? -Ev : Ev;
                    if (Ev <  0) allpos = 1'b0;
                    if (Ev >  0) allneg = 1'b0;
                    if ((av <= {{(EW-CW-1){1'b0}}, mb}) &&
                        (dv >= 0) && (dv <= sg))
                        onedge = 1'b1;
                end
            end
            case (ptype)
                T_POINT: covered = (cur_x == px2b[8:0]) &&
                                   (cur_y == py2b[8:0]);
                T_LINE:  covered = onedge;
                default: covered = pfill ? (allpos | allneg) : onedge;
            endcase
        end
    end
    assign cov = covered;
endmodule

// --- GPU_compose : painter priority + colour source select ---
// higher slot index overwrites (painter algorithm), then the FILL
// override and the per-mode masking / RGB12->24 expansion.
module GPU_compose(
    input  wire [3:0]   cov,
    input  wire [23:0]  pcol0,
    input  wire [23:0]  pcol1,
    input  wire [23:0]  pcol2,
    input  wire [23:0]  pcol3,
    input  wire         ctl_fill,
    input  wire [23:0]  fill_color,
    input  wire         mode_mux,
    input  wire         mode_rgb,
    input  wire [1:0]   cfg_ctype,
    output wire         cov_any,
    output wire [23:0]  px_rgb_w,
    output wire [3:0]   px_mux_w,
    output wire         pix_on_mono
);
    // expand a stored colour to 24-bit RGB according to colour mode
    function [23:0] rgb_expand;
        input [23:0] c; input [1:0] ct;
        begin
            case (ct)
                2'b10: rgb_expand = {c[11:8],c[11:8], c[7:4],c[7:4], c[3:0],c[3:0]}; // RGB12->24
                default: rgb_expand = c[23:0];                                       // RGB24
            endcase
        end
    endfunction

    // higher slot index overwrites (painter) -- same result as the old
    // ascending overwrite loop
    assign cov_any = cov[3] | cov[2] | cov[1] | cov[0];
    wire [23:0] cov_col = cov[3] ? pcol3 : cov[2] ? pcol2
                        : cov[1] ? pcol1 : cov[0] ? pcol0 : 24'd0;

    wire [23:0] pix_rgb_src  = ctl_fill ? fill_color : cov_col;
    wire [3:0]  pix_mux_src  = ctl_fill ? fill_color[3:0] : cov_col[3:0];
    assign pix_on_mono = ctl_fill ? fill_color[0]   : cov_any;

    // CONFIG GATE: the MUX index path and the RGB-expand path are each
    // masked by their mode line, so only the selected colour pipeline
    // toggles. (rgb_expand sees 0 in MUX mode.)
    assign px_mux_w = pix_mux_src & {4{mode_mux}};
    assign px_rgb_w = rgb_expand(pix_rgb_src & {24{mode_rgb}}, cfg_ctype);
endmodule

module GPU (
    input              clk,
    input              reset,

    // ---- CPU memory-mapped slave ----
    input              gpu_we,
    input      [3:0]   gpu_addr,
    input      [31:0]  gpu_wdata,
    output reg [31:0]  gpu_rdata,

    // ---- screen handshake / control ----
    input              screen_ready,
    output reg         frame_start,
    output reg         frame_done,

    // ---- screen geometry / mode ----
    output     [7:0]   scr_w,
    output     [7:0]   scr_h,
    output     [1:0]   scr_ctype,
    output             enable,
    output             fill,

    // ---- monochrome row path ----
    output reg         mono_valid,
    output reg [7:0]   mono_y,
    output reg [63:0]  mono_s0,
    output reg [63:0]  mono_s1,
    output reg [63:0]  mono_s2,
    output reg [63:0]  mono_s3,

    // ---- colour pixel path ----
    output reg         px_valid,
    output reg [4:0]   px_x,
    output reg [4:0]   px_y,
    output reg [3:0]   px_mux,
    output reg [23:0]  px_rgb
);

    // ---- top-level port colours (BITF-Synth Engine; harmless when GPU is a submodule)
    // define clk          input  97.160.255
    // define reset        input  36.255.145
    // define gpu_we       input  97.153.69
    // define gpu_addr     input  255.190.70
    // define gpu_wdata    input  68.68.242
    // define gpu_rdata    output 120.200.255
    // define screen_ready input  153.43.43
    // define frame_start  output 133.242.24
    // define frame_done   output 120.255.180
    // define scr_w        output 61.153.15
    // define scr_h        output 176.109.242
    // define scr_ctype    output 20.20.199
    // define enable       output 90.255.120
    // define fill         output 255.140.60
    // define mono_valid   output 24.133.242
    // define mono_y       output 109.109.242
    // define mono_s0      output 255.255.255
    // define mono_s1      output 56.199.56
    // define mono_s2      output 199.139.20
    // define mono_s3      output 199.56.80
    // define px_valid     output 68.213.242
    // define px_x         output 24.242.97
    // define px_y         output 153.15.130
    // define px_mux       output 255.210.120
    // define px_rgb       output 255.60.60

    // ---------------- parameters (adjustable; cost scales with these) -------
    localparam MAX_PRIM = 4;     // primitive slots (painter priority: high idx on top)
    localparam MAX_VERT = 8;     // max vertices per primitive (convex)
    localparam NV       = MAX_PRIM*MAX_VERT;  // 32 vertex cells
    localparam NE       = MAX_PRIM*MAX_VERT;  // 32 edge cells (1 per vertex)
    localparam CW       = 12;    // signed screen-coord width
    localparam EW       = 32;    // signed edge-accumulator width

    localparam T_POINT = 2'd0, T_LINE = 2'd1, T_POLY = 2'd2;

    // ---------------- configuration / control registers ---------------------
    reg  [7:0] cfg_w, cfg_h;     // width-1 / height-1 fields
    reg  [1:0] cfg_ctype;
    reg        cfg_proj;
    reg        ctl_enable, ctl_fill, ctl_wait, ctl_cont;
    reg  [7:0] rot_ax, rot_ay, rot_az;
    reg [23:0] fill_color;
    reg  [3:0] sel_slot, sel_vert;

    assign scr_w     = cfg_w;
    assign scr_h     = cfg_h;
    assign scr_ctype = cfg_ctype;
    assign enable    = ctl_enable;
    assign fill      = ctl_fill;

    // ---------------- CONFIG decode + FRONT-MUX (GPU_cfgdec) ----------------
    // resolution clamp, screen centre, mode one-hots, projection select --
    // see the GPU_cfgdec module above (expressions carried over verbatim).
    wire [8:0] res_w, res_h;
    wire       is_mono;
    wire signed [CW-1:0] cx, cy;
    wire mode_mono, mode_mux, mode_rgb12, mode_rgb24, mode_rgb;
    wire proj_iso, proj_ortho;
    GPU_cfgdec u_cfgdec(
        .cfg_w(cfg_w), .cfg_h(cfg_h),
        .cfg_ctype(cfg_ctype), .cfg_proj(cfg_proj),
        .res_w(res_w), .res_h(res_h), .is_mono(is_mono),
        .cx(cx), .cy(cy),
        .mode_mono(mode_mono), .mode_mux(mode_mux),
        .mode_rgb12(mode_rgb12), .mode_rgb24(mode_rgb24),
        .mode_rgb(mode_rgb),
        .proj_iso(proj_iso), .proj_ortho(proj_ortho)
    );
    reg               p_en   [0:MAX_PRIM-1];   // slot enable (scene store)
    reg  [1:0]        p_type [0:MAX_PRIM-1];
    reg               p_is3d [0:MAX_PRIM-1];
    reg               p_fill [0:MAX_PRIM-1];
    reg  [3:0]        p_vcnt [0:MAX_PRIM-1];
    reg [23:0]        p_col  [0:MAX_PRIM-1];

    reg signed [CW-1:0] vx [0:NV-1];   // raw vertices (model/screen space)
    reg signed [CW-1:0] vy [0:NV-1];
    reg signed [CW-1:0] vz [0:NV-1];
    reg signed [CW-1:0] px2[0:NV-1];   // projected 2D screen coords
    reg signed [CW-1:0] py2[0:NV-1];

    // edge coefficients : E(x,y) = A*x + B*y + C ,  A=dy , B=-dx
    reg signed [CW:0]   e_dy   [0:NE-1];   // A  (and +x step for E)
    reg signed [CW:0]   e_dx   [0:NE-1];   // +x step for dot
    reg signed [CW:0]   e_ndx  [0:NE-1];   // B = -dx
    reg signed [EW-1:0] e_C    [0:NE-1];
    reg signed [EW-1:0] e_Ddot [0:NE-1];
    reg signed [EW-1:0] e_seg2 [0:NE-1];
    reg signed [CW:0]   e_mab  [0:NE-1];   // max(|dx|,|dy|) ~ 1px outline threshold
    reg signed [EW-1:0] e_E    [0:NE-1];   // running edge value at current pixel
    reg signed [EW-1:0] e_dot  [0:NE-1];   // running along-edge dot at current pixel

    integer i;

    // trig values latched for the current frame; the Q1.8 sine LUT lives
    // in GPU_sin above (one instance per value, cos(a) = sin(a+64))
    reg signed [10:0] sx_, cx_, sy_, cy_, sz_, cz_;
    wire signed [10:0] sin_ax, cos_ax, sin_ay, cos_ay, sin_az, cos_az;
    GPU_sin u_sin_ax(.a(rot_ax),          .s(sin_ax));
    GPU_sin u_cos_ax(.a(rot_ax + 8'd64),  .s(cos_ax));
    GPU_sin u_sin_ay(.a(rot_ay),          .s(sin_ay));
    GPU_sin u_cos_ay(.a(rot_ay + 8'd64),  .s(cos_ay));
    GPU_sin u_sin_az(.a(rot_az),          .s(sin_az));
    GPU_sin u_cos_az(.a(rot_az + 8'd64),  .s(cos_az));

    // ---------------- main FSM ----------------------------------------------
    localparam S_IDLE   = 4'd0,
               S_TRIG   = 4'd1,
               S_XFORM  = 4'd2,
               S_EDGE   = 4'd3,
               S_FRAME  = 4'd4,
               S_ROWINI = 4'd5,
               S_PIXEL  = 4'd6,
               S_ROWEMT = 4'd7,
               S_ROWEND = 4'd8,
               S_DONE   = 4'd9;

    reg [3:0]  state;
    reg [5:0]  idx_v;          // vertex iterator 0..NV
    reg [5:0]  idx_e;          // edge iterator 0..NE

    // ---- PROCESS FRONT-MUX (only the active stage's logic toggles) ---------
    // Exactly one stage runs per cycle, so these one-hot enables gate the
    // operands of each stage. The big per-pixel coverage net in particular is
    // frozen unless pixel_en is high, so it does not toggle during the per-row
    // edge-seed pass or any other state.
    wire xform_en  = (state == S_XFORM);
    wire edge_en   = (state == S_EDGE);
    wire rowini_en = (state == S_ROWINI);
    wire pixel_en  = (state == S_PIXEL);
    reg [1:0]  sub;            // sub-step within transform / edge setup
    reg [8:0]  cur_x, cur_y;   // scan position
    reg        busy;

    // transform scratch
    reg signed [CW-1:0] tx, ty, tz;            // working vertex
    reg signed [CW+12:0] mm0, mm1, mm2, mm3;   // shared products (4 multipliers)
    reg signed [CW-1:0] fx, fy, fz, sxp, syp;  // projection temporaries
    reg signed [CW-1:0] fz_iso, sy_skew;       // iso-only terms (gated by proj_iso)

    // helpers to map an edge index to its slot / vertices
    // slot = idx_e / MAX_VERT ; local e = idx_e % MAX_VERT
    reg [1:0] es;          // edge slot
    reg [3:0] ee;          // edge local index
    reg [3:0] enext;       // next vertex (wrap by vcount)
    reg signed [CW-1:0] x0e, y0e, x1e, y1e, dxe, dye;

    // ----- combinational per-pixel coverage over the scene ------------------
    // one GPU_slot_cov instance per primitive slot (the old in-line loop,
    // see the module above), then GPU_compose for painter priority + the
    // colour source select. The edge arrays are packed onto flat buses so
    // the slot units can receive them through ports.
    genvar gk;
    wire [NE*EW-1:0]   eE_flat;
    wire [NE*EW-1:0]   edot_flat;
    wire [NE*EW-1:0]   eseg2_flat;
    wire [NE*13-1:0]   emab_flat;
    generate for (gk = 0; gk < NE; gk = gk + 1) begin : PACK
        assign eE_flat   [gk*EW +: EW] = e_E   [gk];
        assign edot_flat [gk*EW +: EW] = e_dot [gk];
        assign eseg2_flat[gk*EW +: EW] = e_seg2[gk];
        assign emab_flat [gk*13 +: 13] = e_mab [gk];
    end endgenerate

    wire pixel_en_w = pixel_en;
    wire [3:0] cov;
    GPU_slot_cov u_cov0(
        .pixel_en(pixel_en_w), .en(p_en[0]), .ptype(p_type[0]),
        .pfill(p_fill[0]), .pvcnt(p_vcnt[0]),
        .cur_x(cur_x), .cur_y(cur_y),
        .px2b(px2[0*MAX_VERT]), .py2b(py2[0*MAX_VERT]),
        .eE_flat(eE_flat[0*8*EW +: 8*EW]),
        .edot_flat(edot_flat[0*8*EW +: 8*EW]),
        .eseg2_flat(eseg2_flat[0*8*EW +: 8*EW]),
        .emab_flat(emab_flat[0*8*13 +: 8*13]),
        .cov(cov[0]));
    GPU_slot_cov u_cov1(
        .pixel_en(pixel_en_w), .en(p_en[1]), .ptype(p_type[1]),
        .pfill(p_fill[1]), .pvcnt(p_vcnt[1]),
        .cur_x(cur_x), .cur_y(cur_y),
        .px2b(px2[1*MAX_VERT]), .py2b(py2[1*MAX_VERT]),
        .eE_flat(eE_flat[1*8*EW +: 8*EW]),
        .edot_flat(edot_flat[1*8*EW +: 8*EW]),
        .eseg2_flat(eseg2_flat[1*8*EW +: 8*EW]),
        .emab_flat(emab_flat[1*8*13 +: 8*13]),
        .cov(cov[1]));
    GPU_slot_cov u_cov2(
        .pixel_en(pixel_en_w), .en(p_en[2]), .ptype(p_type[2]),
        .pfill(p_fill[2]), .pvcnt(p_vcnt[2]),
        .cur_x(cur_x), .cur_y(cur_y),
        .px2b(px2[2*MAX_VERT]), .py2b(py2[2*MAX_VERT]),
        .eE_flat(eE_flat[2*8*EW +: 8*EW]),
        .edot_flat(edot_flat[2*8*EW +: 8*EW]),
        .eseg2_flat(eseg2_flat[2*8*EW +: 8*EW]),
        .emab_flat(emab_flat[2*8*13 +: 8*13]),
        .cov(cov[2]));
    GPU_slot_cov u_cov3(
        .pixel_en(pixel_en_w), .en(p_en[3]), .ptype(p_type[3]),
        .pfill(p_fill[3]), .pvcnt(p_vcnt[3]),
        .cur_x(cur_x), .cur_y(cur_y),
        .px2b(px2[3*MAX_VERT]), .py2b(py2[3*MAX_VERT]),
        .eE_flat(eE_flat[3*8*EW +: 8*EW]),
        .edot_flat(edot_flat[3*8*EW +: 8*EW]),
        .eseg2_flat(eseg2_flat[3*8*EW +: 8*EW]),
        .emab_flat(emab_flat[3*8*13 +: 8*13]),
        .cov(cov[3]));

    wire        cov_any;
    wire [23:0] px_rgb_w;
    wire [3:0]  px_mux_w;
    wire        pix_on_mono;
    GPU_compose u_compose(
        .cov(cov),
        .pcol0(p_col[0]), .pcol1(p_col[1]),
        .pcol2(p_col[2]), .pcol3(p_col[3]),
        .ctl_fill(ctl_fill), .fill_color(fill_color),
        .mode_mux(mode_mux), .mode_rgb(mode_rgb),
        .cfg_ctype(cfg_ctype),
        .cov_any(cov_any),
        .px_rgb_w(px_rgb_w), .px_mux_w(px_mux_w),
        .pix_on_mono(pix_on_mono)
    );

    wire advance = (~ctl_wait) | screen_ready;   // free-run unless waiting

    // ============================ sequential ================================
    always @(posedge clk) begin
        if (reset) begin
            state <= S_IDLE; busy <= 1'b0;
            cfg_w <= 8'd63; cfg_h <= 8'd63; cfg_ctype <= 2'b00; cfg_proj <= 1'b0;
            ctl_enable <= 1'b0; ctl_fill <= 1'b0; ctl_wait <= 1'b0; ctl_cont <= 1'b0;
            rot_ax <= 8'd0; rot_ay <= 8'd0; rot_az <= 8'd0;
            fill_color <= 24'd0; sel_slot <= 4'd0; sel_vert <= 4'd0;
            mono_valid <= 1'b0; px_valid <= 1'b0; frame_start <= 1'b0; frame_done <= 1'b0;
            mono_y <= 8'd0; px_x <= 5'd0; px_y <= 5'd0; px_mux <= 4'd0; px_rgb <= 24'd0;
            mono_s0 <= 64'd0; mono_s1 <= 64'd0; mono_s2 <= 64'd0; mono_s3 <= 64'd0;
            for (i = 0; i < MAX_PRIM; i = i + 1) begin
                p_en[i] <= 1'b0; p_type[i] <= 2'd0; p_is3d[i] <= 1'b0;
                p_fill[i] <= 1'b0; p_vcnt[i] <= 4'd0; p_col[i] <= 24'd0;
            end
        end else begin
            // -------- register writes from the CPU (always serviced) --------
            if (gpu_we) begin
                case (gpu_addr)
                    4'd0: begin cfg_w <= gpu_wdata[7:0]; cfg_h <= gpu_wdata[15:8];
                                cfg_ctype <= gpu_wdata[17:16]; cfg_proj <= gpu_wdata[18]; end
                    4'd1: begin ctl_enable <= gpu_wdata[0]; ctl_fill <= gpu_wdata[1];
                                ctl_wait <= gpu_wdata[3]; ctl_cont <= gpu_wdata[5];
                                if (gpu_wdata[2]) begin                 // scene_clear
                                    for (i = 0; i < MAX_PRIM; i = i + 1) p_en[i] <= 1'b0;
                                end
                                // commit handled below by state machine trigger
                          end
                    4'd2: begin rot_ax <= gpu_wdata[7:0]; rot_ay <= gpu_wdata[15:8];
                                rot_az <= gpu_wdata[23:16]; end
                    4'd3: fill_color <= gpu_wdata[23:0];
                    4'd4: begin sel_slot <= gpu_wdata[3:0]; sel_vert <= gpu_wdata[7:4]; end
                    4'd5: begin p_type[sel_slot[1:0]] <= gpu_wdata[1:0];
                                p_is3d[sel_slot[1:0]] <= gpu_wdata[2];
                                p_fill[sel_slot[1:0]] <= gpu_wdata[3];
                                p_en  [sel_slot[1:0]] <= gpu_wdata[4];
                                p_vcnt[sel_slot[1:0]] <= gpu_wdata[8:5]; end
                    4'd6: p_col[sel_slot[1:0]] <= gpu_wdata[23:0];
                    4'd7: begin
                                vx[{sel_slot[1:0],sel_vert[2:0]}] <= $signed(gpu_wdata[9:0]);
                                vy[{sel_slot[1:0],sel_vert[2:0]}] <= $signed(gpu_wdata[19:10]);
                                vz[{sel_slot[1:0],sel_vert[2:0]}] <= $signed(gpu_wdata[29:20]);
                                sel_vert <= sel_vert + 4'd1;
                          end
                    default: ;
                endcase
            end

            // strobe / valid defaults (asserted only by the presenting states)
            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            mono_valid  <= 1'b0;
            px_valid    <= 1'b0;

            // status read
            gpu_rdata <= {22'd0, frame_done, busy, cur_y[7:0]};

            // -------- the rendering pipeline --------------------------------
            case (state)
            // wait for commit (CONTROL bit4)
            S_IDLE: begin
                busy <= 1'b0;
                if (gpu_we && gpu_addr == 4'd1 && gpu_wdata[4]) begin
                    busy  <= 1'b1;
                    state <= S_TRIG;
                end
            end

            // latch sin/cos for this frame
            S_TRIG: begin
                sx_ <= sin_ax;  cx_ <= cos_ax;
                sy_ <= sin_ay;  cy_ <= cos_ay;
                sz_ <= sin_az;  cz_ <= cos_az;
                idx_v <= 6'd0; sub <= 2'd0;
                state <= S_XFORM;
            end

            // transform + project every vertex (4 shared multipliers, 3 substeps)
            S_XFORM: begin
                if (idx_v == NV) begin
                    idx_e <= 6'd0; sub <= 2'd0; state <= S_EDGE;
                end else if (!p_en[idx_v[4:3]] ||
                             (idx_v[2:0] >= p_vcnt[idx_v[4:3]])) begin
                    idx_v <= idx_v + 6'd1; sub <= 2'd0;          // skip unused cell
                end else if (!p_is3d[idx_v[4:3]]) begin
                    px2[idx_v] <= vx[idx_v];                      // 2D : screen coords
                    py2[idx_v] <= vy[idx_v];
                    idx_v <= idx_v + 6'd1; sub <= 2'd0;
                end else begin
                    case (sub)
                    2'd0: begin                                   // load + rotate X
                        tx <= vx[idx_v];
                        mm0 = vy[idx_v]*cx_; mm1 = vz[idx_v]*sx_;
                        mm2 = vy[idx_v]*sx_; mm3 = vz[idx_v]*cx_;
                        ty <= (mm0 - mm1) >>> 8;
                        tz <= (mm2 + mm3) >>> 8;
                        sub <= 2'd1;
                    end
                    2'd1: begin                                   // rotate Y
                        mm0 = tx*cy_; mm1 = tz*sy_;
                        mm2 = tx*sy_; mm3 = tz*cy_;
                        tx <= (mm0 + mm1) >>> 8;
                        tz <= (mm3 - mm2) >>> 8;
                        sub <= 2'd2;
                    end
                    default: begin                                // rotate Z + project
                        mm0 = tx*cz_; mm1 = ty*sz_;
                        mm2 = tx*sz_; mm3 = ty*cz_;
                        fx = (mm0 - mm1) >>> 8;
                        fy = (mm2 + mm3) >>> 8;
                        fz = tz;
                        // CONFIG GATE: iso skew operands masked by proj_iso.
                        // In ortho mode fz_iso and sy_skew are 0, so the skew
                        // subtractor/adder/shifter inputs are 0 and inactive.
                        fz_iso  = fz & {CW{proj_iso}};
                        sy_skew = ((fx + fz_iso) >>> 1) & {CW{proj_iso}};
                        sxp = fx - fz_iso;          // fx in ortho, fx-fz in iso
                        syp = fy + sy_skew;         // fy in ortho, fy+(fx+fz)/2 in iso
                        px2[idx_v] <= sxp + cx;
                        py2[idx_v] <= syp + cy;
                        idx_v <= idx_v + 6'd1; sub <= 2'd0;
                    end
                    endcase
                end
            end

            // build edge coefficients (2 shared multipliers, 3 substeps/edge)
            S_EDGE: begin
                es    = idx_e[4:3];
                ee    = {1'b0,idx_e[2:0]};
                enext = (ee + 4'd1 >= p_vcnt[es]) ? 4'd0 : (ee + 4'd1);
                x0e   = px2[idx_e];
                y0e   = py2[idx_e];
                x1e   = px2[{es,enext[2:0]}];
                y1e   = py2[{es,enext[2:0]}];
                dxe   = x1e - x0e;
                dye   = y1e - y0e;
                if (idx_e == NE) begin
                    cur_y <= 9'd0; state <= S_FRAME;
                end else if (!p_en[es] || (ee >= p_vcnt[es])) begin
                    e_dy[idx_e]  <= 0; e_dx[idx_e] <= 0; e_ndx[idx_e] <= 0;
                    e_C[idx_e]   <= 0; e_Ddot[idx_e]<= 0; e_seg2[idx_e]<= 0;
                    e_mab[idx_e] <= 0;
                    idx_e <= idx_e + 6'd1; sub <= 2'd0;
                end else begin
                    case (sub)
                    2'd0: begin
                        e_dy [idx_e] <= dye;
                        e_dx [idx_e] <= dxe;
                        e_ndx[idx_e] <= -dxe;
                        e_mab[idx_e] <= ((dye<0?-dye:dye) > (dxe<0?-dxe:dxe))
                                        ? (dye<0?-dye:dye) : (dxe<0?-dxe:dxe);
                        mm0 = dxe*y0e; mm1 = dye*x0e;            // C = dx*y0 - dy*x0
                        e_C[idx_e] <= mm0 - mm1;
                        sub <= 2'd1;
                    end
                    2'd1: begin
                        mm0 = x0e*dxe; mm1 = y0e*dye;            // Ddot = -(x0*dx + y0*dy)
                        e_Ddot[idx_e] <= -(mm0 + mm1);
                        sub <= 2'd2;
                    end
                    default: begin
                        mm0 = dxe*dxe; mm1 = dye*dye;            // seg2 = dx^2 + dy^2
                        e_seg2[idx_e] <= mm0 + mm1;
                        idx_e <= idx_e + 6'd1; sub <= 2'd0;
                    end
                    endcase
                end
            end

            // start of frame
            S_FRAME: begin
                frame_start <= 1'b1;
                cur_y <= 9'd0;
                idx_e <= 6'd0;
                state <= S_ROWINI;
            end

            // per-row: seed each edge accumulator at x=0 (2 shared multipliers)
            S_ROWINI: begin
                if (idx_e == NE) begin
                    cur_x <= 9'd0;
                    mono_s0 <= 64'd0; mono_s1 <= 64'd0;
                    mono_s2 <= 64'd0; mono_s3 <= 64'd0;
                    state <= S_PIXEL;
                end else begin
                    mm0 = e_ndx[idx_e]*$signed({3'b000,cur_y});  // B*y
                    mm1 = e_dy [idx_e]*$signed({3'b000,cur_y});  // dy*y
                    e_E  [idx_e] <= mm0 + e_C[idx_e];
                    e_dot[idx_e] <= mm1 + e_Ddot[idx_e];
                    idx_e <= idx_e + 6'd1;
                end
            end

            // per-pixel: sample coverage, then step every edge accumulator by +x
            S_PIXEL: begin
                if (is_mono) begin
                    // write current bit into the row register
                    if (pix_on_mono) begin
                        case (cur_x[7:6])
                            2'd0: mono_s0[cur_x[5:0]] <= 1'b1;
                            2'd1: mono_s1[cur_x[5:0]] <= 1'b1;
                            2'd2: mono_s2[cur_x[5:0]] <= 1'b1;
                            default: mono_s3[cur_x[5:0]] <= 1'b1;
                        endcase
                    end
                    for (i = 0; i < NE; i = i + 1) begin
                        e_E[i]   <= e_E[i]   + {{(EW-CW-1){e_dy[i][CW]}}, e_dy[i]};
                        e_dot[i] <= e_dot[i] + {{(EW-CW-1){e_dx[i][CW]}}, e_dx[i]};
                    end
                    if (cur_x + 9'd1 >= res_w) begin
                        state <= S_ROWEMT;
                    end else begin
                        cur_x <= cur_x + 9'd1;
                    end
                end else begin
                    // colour: present this pixel, wait for handshake
                    // CONFIG GATE: the MUX index path and the RGB-expand path
                    // are each masked by their mode line, so only the selected
                    // colour pipeline toggles. (rgb_expand sees 0 in MUX mode.)
                    px_valid <= ctl_enable;
                    px_x  <= cur_x[4:0];
                    px_y  <= cur_y[4:0];
                    px_mux<= px_mux_w;
                    px_rgb<= px_rgb_w;
                    // consume only a pixel that is already VISIBLE outside
                    // (px_valid is registered): a ready arriving on the
                    // presentation cycle itself must not step the scan, or
                    // that pixel is skipped without ever being seen.
                    if (advance && px_valid) begin
                        for (i = 0; i < NE; i = i + 1) begin
                            e_E[i]   <= e_E[i]   + {{(EW-CW-1){e_dy[i][CW]}}, e_dy[i]};
                            e_dot[i] <= e_dot[i] + {{(EW-CW-1){e_dx[i][CW]}}, e_dx[i]};
                        end
                        if (cur_x + 9'd1 >= res_w) begin
                            state <= S_ROWEND;
                        end else begin
                            cur_x <= cur_x + 9'd1;
                        end
                    end
                end
            end

            // monochrome: present the completed row, wait for handshake
            S_ROWEMT: begin
                mono_valid <= ctl_enable;
                mono_y <= cur_y[7:0];
                // same visibility rule as the pixel path: only consume a
                // row the outside world has already been shown
                if (advance && mono_valid) begin
                    state <= S_ROWEND;
                end
            end

            // advance to next row / finish frame
            S_ROWEND: begin
                if (cur_y + 9'd1 >= res_h) begin
                    state <= S_DONE;
                end else begin
                    cur_y <= cur_y + 9'd1;
                    idx_e <= 6'd0;
                    state <= S_ROWINI;
                end
            end

            // frame complete
            S_DONE: begin
                frame_done <= 1'b1;
                if (ctl_cont) state <= S_TRIG;     // auto re-render (animation)
                else          state <= S_IDLE;
            end

            default: state <= S_IDLE;
            endcase
        end
    end
endmodule
