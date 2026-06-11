"""
gen_gpus.py  ->  src/GPUs/gpu_dot8.v        8x8  mono,  4 point slots, row-serial
                 src/GPUs/gpu_sprite16.v   16x16 MUX,   4 sprite stamps (8x8, 1bpp)
                 src/GPUs/gpu_vector32.v   32x32 RGB12, 8 slots point/hline/vline/rect
                 src/GPUs/gpu_raster64.v   64x64 mono,  4 triangle slots, edge functions
                 src/GPUs/gpu_pipelined32.v 32x32 RGB24, 8 slots, 3-STAGE pixel pipeline

A difficulty ladder up to the hand-written flagship src/GPUs/GPU.v. Every
design speaks the SAME bus and conventions as the flagship:

  * MMIO: gpu_we / gpu_addr[3:0] / gpu_wdata[31:0] writes, gpu_rdata reads
  * CONTROL (addr 1) bits: 0 enable, 1 fill, 2 scene_clear*, 3 wait_for_screen,
    4 commit*, 5 continuous                       (* = self-clearing strobe)
  * scene registers are STAGED and only become visible on commit
    (double-buffered scene store -> tear-free updates)
  * racing-the-beam scanout: no framebuffer anywhere; pixels/rows are
    computed in scan order and presented through the screen_ready handshake
    (wait_for_screen=1) or free-run (slow the clock)
  * frame_start / frame_done pulse at the scan boundaries
  * operand isolation in the per-slot coverage logic (flagship technique)

gpu_raster64 demonstrates the flagship's triangle technique: edge functions
E(x,y) = A*x + B*y + C are SEEDED with multiplies once at commit, then
stepped purely incrementally (E += A per pixel, row start += B per row).
gpu_pipelined32 demonstrates the flagship CPU convention of external
PIPELINE SYNCHRONIZER strobes (ppln_*) gating the per-class datapaths.
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from _common import banner, write

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "GPUs")

CTL_COMMENT = """\
//  REGISTER MAP (gpu_addr):
//   1  CONTROL  { continuous, wait_for_screen, scene_clear*, commit*,
//                 fill, enable }                 (* = self-clearing strobe)
"""

DEFINE_BUS = """\
    // define clk          input  97.160.255
    // define reset        input  36.255.145
    // define gpu_we       input  97.153.69
    // define gpu_addr     input  255.190.70
    // define gpu_wdata    input  68.68.242
    // define gpu_rdata    output 120.200.255
    // define screen_ready input  153.43.43
    // define frame_start  output 133.242.24
    // define frame_done   output 120.255.180
    // define enable       output 90.255.120
    // define fill         output 255.140.60
"""


def bus_ports(extra_in="", extra_out=""):
    return (
        "    input              clk,\n"
        "    input              reset,\n"
        "    input              gpu_we,\n"
        "    input      [3:0]   gpu_addr,\n"
        "    input      [31:0]  gpu_wdata,\n"
        "    output reg [31:0]  gpu_rdata,\n"
        + extra_in +
        "    input              screen_ready,\n"
        "    output reg         frame_start,\n"
        "    output reg         frame_done,\n"
        "    output             enable,\n"
        "    output             fill,\n"
        + extra_out
    )


CTL_DECL = """\
    // ---- CONTROL register (flagship bit map) ------------------------------
    reg ctl_enable, ctl_fill, ctl_wait, ctl_cont;
    assign enable = ctl_enable;
    assign fill   = ctl_fill;
    wire advance = (~ctl_wait) | screen_ready;   // free-run unless waiting
"""


def ctl_write(scene_clear_body):
    """The CONTROL write decode, with a hook for scene_clear."""
    s = []
    s.append("                4'd1: begin")
    s.append("                    ctl_enable <= gpu_wdata[0];")
    s.append("                    ctl_fill   <= gpu_wdata[1];")
    s.append("                    ctl_wait   <= gpu_wdata[3];")
    s.append("                    ctl_cont   <= gpu_wdata[5];")
    if scene_clear_body:
        s.append("                    if (gpu_wdata[2]) begin          // scene_clear*")
        for ln in scene_clear_body:
            s.append("                        " + ln)
        s.append("                    end")
    s.append("                    // commit (bit 4) is sampled by the scan FSM below")
    s.append("                end")
    return "\n".join(s)


COMMIT_WIRE = """\
    wire commit_strobe = gpu_we && (gpu_addr == 4'd1) && gpu_wdata[4];
"""


# ===========================================================================
#  1) gpu_dot8 -- the "hello world" GPU
# ===========================================================================

def gen_dot8():
    name = "gpu_dot8"
    hdr = banner(name + ".v", [
        "8x8 MONOCHROME point-plotter GPU -- the smallest member of the",
        "family and the gentlest introduction to the flagship conventions:",
        "MMIO scene store, double-buffered commit, racing-the-beam ROW-serial",
        "scanout (no framebuffer), screen_ready handshake, frame strobes.",
        "Scene: 4 point slots. Same bus + CONTROL bit map as src/GPUs/GPU.v.",
    ])
    body = f"""//  {name}: 4 point slots on an 8x8 monochrome screen, row-serial scanout.
//
//  MMIO: gpu_we / gpu_addr[3:0] / gpu_wdata[31:0] -> writes, gpu_rdata reads
{CTL_COMMENT}//   4  SEL      {{ slot[1:0] }}                  selects the staging slot
//   5  PRIMHDR  {{ en = bit4 }}                  enables slot SEL.slot
//   7  VERT     {{ y[2:0] = bits[12:10], x[2:0] = bits[2:0] }}
//   read -> STATUS {{ 22'd0, frame_done, busy, 5'd0, cur_y[2:0] }}
//
//  Writes land in a STAGING copy of the scene; CONTROL.commit* flips the
//  staging copy into the ACTIVE copy between frames (tear-free updates).
//  SCANOUT: one 8-bit row bitmap per handshake (racing the beam, no
//  framebuffer). CONTROL.fill floods every row with 8'hFF.
//
module {name} (
{bus_ports(extra_out=(
    "    output reg         mono_valid,\n"
    "    output reg [2:0]   mono_y,\n"
    "    output reg [7:0]   mono_row\n"
))});

{DEFINE_BUS}    // define mono_valid   output 24.133.242
    // define mono_y       output 109.109.242
    // define mono_row     output 255.255.255

{CTL_DECL}
    // ---- scene store: staging + active (double-buffered) ------------------
    reg        s_en [0:3];     reg        a_en [0:3];
    reg [2:0]  s_x  [0:3];     reg [2:0]  a_x  [0:3];
    reg [2:0]  s_y  [0:3];     reg [2:0]  a_y  [0:3];
    reg [1:0]  sel_slot;

{COMMIT_WIRE}
    // ---- row composer: OR of every active point on this row ---------------
    // (operand isolation: a slot's decoder only fires while its enable is
    //  high, so disabled slots contribute constant zeros)
    reg [2:0] cur_y;
    wire [7:0] hit0 = (a_en[0] && a_y[0] == cur_y) ? (8'd1 << a_x[0]) : 8'd0;
    wire [7:0] hit1 = (a_en[1] && a_y[1] == cur_y) ? (8'd1 << a_x[1]) : 8'd0;
    wire [7:0] hit2 = (a_en[2] && a_y[2] == cur_y) ? (8'd1 << a_x[2]) : 8'd0;
    wire [7:0] hit3 = (a_en[3] && a_y[3] == cur_y) ? (8'd1 << a_x[3]) : 8'd0;
    wire [7:0] row_pix = ctl_fill ? 8'hFF : (hit0 | hit1 | hit2 | hit3);

    // ---- scan FSM ----------------------------------------------------------
    localparam S_IDLE = 2'd0, S_ROW = 2'd1, S_NEXT = 2'd2;
    reg [1:0] state;
    reg busy;
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            ctl_enable <= 1'b0; ctl_fill <= 1'b0; ctl_wait <= 1'b0; ctl_cont <= 1'b0;
            sel_slot <= 2'd0; state <= S_IDLE; busy <= 1'b0; cur_y <= 3'd0;
            mono_valid <= 1'b0; mono_y <= 3'd0; mono_row <= 8'd0;
            frame_start <= 1'b0; frame_done <= 1'b0; gpu_rdata <= 32'd0;
            for (i = 0; i < 4; i = i + 1) begin
                s_en[i] <= 1'b0; a_en[i] <= 1'b0;
                s_x[i] <= 3'd0; a_x[i] <= 3'd0; s_y[i] <= 3'd0; a_y[i] <= 3'd0;
            end
        end else begin
            // -------- MMIO writes (staging scene) ---------------------------
            if (gpu_we) begin
                case (gpu_addr)
{ctl_write(["s_en[0] <= 1'b0; s_en[1] <= 1'b0;",
            "s_en[2] <= 1'b0; s_en[3] <= 1'b0;"])}
                4'd4: sel_slot <= gpu_wdata[1:0];
                4'd5: s_en[sel_slot] <= gpu_wdata[4];
                4'd7: begin s_x[sel_slot] <= gpu_wdata[2:0];
                            s_y[sel_slot] <= gpu_wdata[12:10]; end
                default: ;
                endcase
            end

            // strobe / valid defaults
            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            mono_valid  <= 1'b0;

            // status read
            gpu_rdata <= {{22'd0, frame_done, busy, 5'd0, cur_y}};

            // -------- the scan ----------------------------------------------
            case (state)
            S_IDLE: begin
                busy <= 1'b0;
                if (commit_strobe) begin
                    for (i = 0; i < 4; i = i + 1) begin   // staging -> active
                        a_en[i] <= s_en[i]; a_x[i] <= s_x[i]; a_y[i] <= s_y[i];
                    end
                    busy <= 1'b1; cur_y <= 3'd0; state <= S_ROW;
                end
            end
            // present one row per handshake (racing the beam)
            S_ROW: if (advance && ctl_enable) begin
                mono_valid <= 1'b1;
                mono_y     <= cur_y;
                mono_row   <= row_pix;
                if (cur_y == 3'd0) frame_start <= 1'b1;
                state <= S_NEXT;
            end
            S_NEXT: begin
                if (cur_y == 3'd7) begin
                    frame_done <= 1'b1;
                    if (ctl_cont) begin cur_y <= 3'd0; state <= S_ROW; end
                    else          begin state <= S_IDLE; end
                end else begin
                    cur_y <= cur_y + 3'd1;
                    state <= S_ROW;
                end
            end
            default: state <= S_IDLE;
            endcase
        end
    end
endmodule
"""
    write(os.path.join(OUT, name + ".v"), hdr + "\n" + body)


# ===========================================================================
#  2) gpu_sprite16 -- sprite stamps with MUX colour
# ===========================================================================

def gen_sprite16():
    name = "gpu_sprite16"
    hdr = banner(name + ".v", [
        "16x16 MUX-COLOUR sprite GPU: four 8x8 1-bpp sprite stamps with",
        "per-sprite 4-bit colour and free (x,y) placement. Pixel-serial",
        "racing-the-beam scanout with painter priority (higher slot wins).",
        "Double-buffered scene store; same bus + CONTROL map as GPU.v.",
    ])
    body = f"""//  {name}: 4 sprite slots (8x8 stamp, 1 bpp, 4-bit MUX colour) on 16x16.
//
//  MMIO: gpu_we / gpu_addr[3:0] / gpu_wdata[31:0] -> writes, gpu_rdata reads
{CTL_COMMENT}//   3  FILLCOLOR {{ mux[3:0] }}        colour used while CONTROL.fill=1
//   4  SEL      {{ row_ptr[6:4], slot[1:0] }}   staging target + stamp row ptr
//   5  PRIMHDR  {{ en = bit4 }}
//   6  PRIMCOL  {{ mux[3:0] }}        sprite colour index
//   7  VERT     {{ y[13:10], x[3:0] }}          top-left corner of the stamp
//   9  STAMPROW {{ bits[7:0] }}       stamp row at SEL.row_ptr (auto-increments)
//   read -> STATUS {{ 22'd0, frame_done, busy, px_y[3:0], px_x[3:0] }}
//
//  SCANOUT: one pixel per handshake -- px_valid / px_x / px_y / px_mux.
//  Coverage per slot is OPERAND-ISOLATED: a disabled slot's position
//  subtractors see all-zero inputs and stay quiet (flagship technique).
//
module {name} (
{bus_ports(extra_out=(
    "    output reg         px_valid,\n"
    "    output reg [3:0]   px_x,\n"
    "    output reg [3:0]   px_y,\n"
    "    output reg [3:0]   px_mux\n"
))});

{DEFINE_BUS}    // define px_valid     output 68.213.242
    // define px_x         output 24.242.97
    // define px_y         output 153.15.130
    // define px_mux       output 255.210.120

{CTL_DECL}
    // ---- scene store: staging + active -------------------------------------
    reg       s_en  [0:3];   reg       a_en  [0:3];
    reg [3:0] s_x   [0:3];   reg [3:0] a_x   [0:3];
    reg [3:0] s_y   [0:3];   reg [3:0] a_y   [0:3];
    reg [3:0] s_col [0:3];   reg [3:0] a_col [0:3];
    reg [7:0] s_stamp [0:31];   // 4 slots x 8 rows  ({{slot,row}})
    reg [7:0] a_stamp [0:31];
    reg [3:0] fill_col;
    reg [1:0] sel_slot;
    reg [2:0] sel_row;

{COMMIT_WIRE}
    // ---- per-slot coverage at scan position (x,y) ---------------------------
    reg [3:0] sx, sy;          // scan position

    // operand isolation: gate the position inputs of each comparator
    //   dx = sx - a_x : in-stamp when 0..7 ; same for dy
    wire [3:0] q0x = sx & {{4{{a_en[0]}}}};  wire [3:0] q0y = sy & {{4{{a_en[0]}}}};
    wire [3:0] q1x = sx & {{4{{a_en[1]}}}};  wire [3:0] q1y = sy & {{4{{a_en[1]}}}};
    wire [3:0] q2x = sx & {{4{{a_en[2]}}}};  wire [3:0] q2y = sy & {{4{{a_en[2]}}}};
    wire [3:0] q3x = sx & {{4{{a_en[3]}}}};  wire [3:0] q3y = sy & {{4{{a_en[3]}}}};

    wire [4:0] d0x = {{1'b0,q0x}} - {{1'b0,a_x[0]}};  wire [4:0] d0y = {{1'b0,q0y}} - {{1'b0,a_y[0]}};
    wire [4:0] d1x = {{1'b0,q1x}} - {{1'b0,a_x[1]}};  wire [4:0] d1y = {{1'b0,q1y}} - {{1'b0,a_y[1]}};
    wire [4:0] d2x = {{1'b0,q2x}} - {{1'b0,a_x[2]}};  wire [4:0] d2y = {{1'b0,q2y}} - {{1'b0,a_y[2]}};
    wire [4:0] d3x = {{1'b0,q3x}} - {{1'b0,a_x[3]}};  wire [4:0] d3y = {{1'b0,q3y}} - {{1'b0,a_y[3]}};

    wire in0 = a_en[0] & ~d0x[4] & (d0x[3:0] < 4'd8) & ~d0y[4] & (d0y[3:0] < 4'd8);
    wire in1 = a_en[1] & ~d1x[4] & (d1x[3:0] < 4'd8) & ~d1y[4] & (d1y[3:0] < 4'd8);
    wire in2 = a_en[2] & ~d2x[4] & (d2x[3:0] < 4'd8) & ~d2y[4] & (d2y[3:0] < 4'd8);
    wire in3 = a_en[3] & ~d3x[4] & (d3x[3:0] < 4'd8) & ~d3y[4] & (d3y[3:0] < 4'd8);

    wire c0 = in0 & a_stamp[{{2'd0, d0y[2:0]}}][d0x[2:0]];
    wire c1 = in1 & a_stamp[{{2'd1, d1y[2:0]}}][d1x[2:0]];
    wire c2 = in2 & a_stamp[{{2'd2, d2y[2:0]}}][d2x[2:0]];
    wire c3 = in3 & a_stamp[{{2'd3, d3y[2:0]}}][d3x[2:0]];

    // painter priority: highest slot wins
    wire [3:0] scene_mux = c3 ? a_col[3] : c2 ? a_col[2]
                         : c1 ? a_col[1] : c0 ? a_col[0] : 4'd0;
    wire [3:0] pix_mux   = ctl_fill ? fill_col : scene_mux;

    // ---- scan FSM ------------------------------------------------------------
    localparam S_IDLE = 2'd0, S_PIX = 2'd1, S_NEXT = 2'd2;
    reg [1:0] state;
    reg busy;
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            ctl_enable <= 1'b0; ctl_fill <= 1'b0; ctl_wait <= 1'b0; ctl_cont <= 1'b0;
            sel_slot <= 2'd0; sel_row <= 3'd0; fill_col <= 4'd0;
            state <= S_IDLE; busy <= 1'b0; sx <= 4'd0; sy <= 4'd0;
            px_valid <= 1'b0; px_x <= 4'd0; px_y <= 4'd0; px_mux <= 4'd0;
            frame_start <= 1'b0; frame_done <= 1'b0; gpu_rdata <= 32'd0;
            for (i = 0; i < 4; i = i + 1) begin
                s_en[i] <= 1'b0; a_en[i] <= 1'b0;
                s_x[i] <= 4'd0; a_x[i] <= 4'd0; s_y[i] <= 4'd0; a_y[i] <= 4'd0;
                s_col[i] <= 4'd0; a_col[i] <= 4'd0;
            end
            for (i = 0; i < 32; i = i + 1) begin
                s_stamp[i] <= 8'd0; a_stamp[i] <= 8'd0;
            end
        end else begin
            // -------- MMIO writes (staging scene) -----------------------------
            if (gpu_we) begin
                case (gpu_addr)
{ctl_write(["s_en[0] <= 1'b0; s_en[1] <= 1'b0;",
            "s_en[2] <= 1'b0; s_en[3] <= 1'b0;"])}
                4'd3: fill_col <= gpu_wdata[3:0];
                4'd4: begin sel_slot <= gpu_wdata[1:0]; sel_row <= gpu_wdata[6:4]; end
                4'd5: s_en[sel_slot] <= gpu_wdata[4];
                4'd6: s_col[sel_slot] <= gpu_wdata[3:0];
                4'd7: begin s_x[sel_slot] <= gpu_wdata[3:0];
                            s_y[sel_slot] <= gpu_wdata[13:10]; end
                4'd9: begin s_stamp[{{sel_slot, sel_row}}] <= gpu_wdata[7:0];
                            sel_row <= sel_row + 3'd1; end   // auto-increment
                default: ;
                endcase
            end

            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            px_valid    <= 1'b0;

            gpu_rdata <= {{22'd0, frame_done, busy, sy, sx}};

            // -------- the scan -------------------------------------------------
            case (state)
            S_IDLE: begin
                busy <= 1'b0;
                if (commit_strobe) begin
                    for (i = 0; i < 4; i = i + 1) begin
                        a_en[i] <= s_en[i]; a_x[i] <= s_x[i]; a_y[i] <= s_y[i];
                        a_col[i] <= s_col[i];
                    end
                    for (i = 0; i < 32; i = i + 1) a_stamp[i] <= s_stamp[i];
                    busy <= 1'b1; sx <= 4'd0; sy <= 4'd0; state <= S_PIX;
                end
            end
            S_PIX: if (advance && ctl_enable) begin
                px_valid <= 1'b1;
                px_x <= sx; px_y <= sy; px_mux <= pix_mux;
                if (sx == 4'd0 && sy == 4'd0) frame_start <= 1'b1;
                state <= S_NEXT;
            end
            S_NEXT: begin
                if (sx == 4'd15 && sy == 4'd15) begin
                    frame_done <= 1'b1;
                    if (ctl_cont) begin sx <= 4'd0; sy <= 4'd0; state <= S_PIX; end
                    else          begin state <= S_IDLE; end
                end else begin
                    if (sx == 4'd15) begin sx <= 4'd0; sy <= sy + 4'd1; end
                    else             sx <= sx + 4'd1;
                    state <= S_PIX;
                end
            end
            default: state <= S_IDLE;
            endcase
        end
    end
endmodule
"""
    write(os.path.join(OUT, name + ".v"), hdr + "\n" + body)


# ===========================================================================
#  3) gpu_vector32 -- multi-primitive colour GPU (point/hline/vline/rect)
# ===========================================================================

def gen_vector32():
    name = "gpu_vector32"
    hdr = banner(name + ".v", [
        "32x32 RGB12 vector GPU: 8 primitive slots, each point / hline /",
        "vline / rect with its own RGB12 colour. Pixel-serial racing-the-",
        "beam scanout, painter priority (higher slot on top), double-",
        "buffered scene. Same bus + CONTROL bit map as the flagship GPU.v;",
        "RGB12 is nibble-expanded onto px_rgb[23:0] exactly like GPU.v.",
    ])
    body = f"""//  {name}: 8 slots x {{point | hline | vline | rect}} on 32x32, RGB12.
//
//  MMIO: gpu_we / gpu_addr[3:0] / gpu_wdata[31:0] -> writes, gpu_rdata reads
{CTL_COMMENT}//   3  FILLCOLOR {{ rgb12[11:0] }}     colour used while CONTROL.fill=1
//   4  SEL      {{ vert_ptr[4], slot[2:0] }}
//   5  PRIMHDR  {{ en = bit4, type[1:0] = bits[1:0] }}
//                type: 00 point | 01 hline | 10 vline | 11 rect
//   6  PRIMCOL  {{ rgb12[11:0] }}
//   7  VERT     {{ y[14:10], x[4:0] }}  vert 0 = origin, vert 1 = extent
//                (auto-increments SEL.vert_ptr; extents are INCLUSIVE)
//   read -> STATUS {{ 22'd0, frame_done, busy, 3'd0, px_y[4:0] }}
//
//  Coverage tests are OPERAND-ISOLATED per slot: every comparator input is
//  ANDed with the slot enable, so parked slots hold constant zeros.
//
module {name} (
{bus_ports(extra_out=(
    "    output reg         px_valid,\n"
    "    output reg [4:0]   px_x,\n"
    "    output reg [4:0]   px_y,\n"
    "    output reg [23:0]  px_rgb\n"
))});

{DEFINE_BUS}    // define px_valid     output 68.213.242
    // define px_x         output 24.242.97
    // define px_y         output 153.15.130
    // define px_rgb       output 255.60.60

{CTL_DECL}
    // ---- scene store: staging + active --------------------------------------
    reg        s_en  [0:7];   reg        a_en  [0:7];
    reg [1:0]  s_ty  [0:7];   reg [1:0]  a_ty  [0:7];
    reg [11:0] s_col [0:7];   reg [11:0] a_col [0:7];
    reg [4:0]  s_x0  [0:7];   reg [4:0]  a_x0  [0:7];
    reg [4:0]  s_y0  [0:7];   reg [4:0]  a_y0  [0:7];
    reg [4:0]  s_x1  [0:7];   reg [4:0]  a_x1  [0:7];
    reg [4:0]  s_y1  [0:7];   reg [4:0]  a_y1  [0:7];
    reg [11:0] fill_col;
    reg [2:0]  sel_slot;
    reg        sel_vert;

{COMMIT_WIRE}
    reg [4:0] sx, sy;          // scan position

    // ---- per-slot coverage (generate-style, written out per slot) ----------
    // covered(s) =
    //   point: x==x0 && y==y0
    //   hline: y==y0 && x0<=x<=x1
    //   vline: x==x0 && y0<=y<=y1
    //   rect : x0<=x<=x1 && y0<=y<=y1
    wire [7:0] cov;
    genvar g;
    generate for (g = 0; g < 8; g = g + 1) begin : COV
        // operand isolation on the scan coordinates
        wire [4:0] gx = sx & {{5{{a_en[g]}}}};
        wire [4:0] gy = sy & {{5{{a_en[g]}}}};
        wire xe = (gx == a_x0[g]);
        wire ye = (gy == a_y0[g]);
        wire xr = (gx >= a_x0[g]) & (gx <= a_x1[g]);
        wire yr = (gy >= a_y0[g]) & (gy <= a_y1[g]);
        assign cov[g] = a_en[g] & (
              (a_ty[g] == 2'd0) ? (xe & ye)
            : (a_ty[g] == 2'd1) ? (ye & xr)
            : (a_ty[g] == 2'd2) ? (xe & yr)
            :                     (xr & yr));
    end endgenerate

    // painter priority: highest covering slot wins
    wire [11:0] scene_col =
          cov[7] ? a_col[7] : cov[6] ? a_col[6]
        : cov[5] ? a_col[5] : cov[4] ? a_col[4]
        : cov[3] ? a_col[3] : cov[2] ? a_col[2]
        : cov[1] ? a_col[1] : cov[0] ? a_col[0] : 12'd0;
    wire [11:0] pix12 = ctl_fill ? fill_col : scene_col;
    // RGB12 -> RGB24 nibble expansion (flagship convention)
    wire [23:0] pix_rgb_w = {{pix12[11:8], pix12[11:8],
                             pix12[7:4],  pix12[7:4],
                             pix12[3:0],  pix12[3:0]}};

    // ---- scan FSM -------------------------------------------------------------
    localparam S_IDLE = 2'd0, S_PIX = 2'd1, S_NEXT = 2'd2;
    reg [1:0] state;
    reg busy;
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            ctl_enable <= 1'b0; ctl_fill <= 1'b0; ctl_wait <= 1'b0; ctl_cont <= 1'b0;
            sel_slot <= 3'd0; sel_vert <= 1'b0; fill_col <= 12'd0;
            state <= S_IDLE; busy <= 1'b0; sx <= 5'd0; sy <= 5'd0;
            px_valid <= 1'b0; px_x <= 5'd0; px_y <= 5'd0; px_rgb <= 24'd0;
            frame_start <= 1'b0; frame_done <= 1'b0; gpu_rdata <= 32'd0;
            for (i = 0; i < 8; i = i + 1) begin
                s_en[i] <= 1'b0; a_en[i] <= 1'b0;
                s_ty[i] <= 2'd0; a_ty[i] <= 2'd0;
                s_col[i] <= 12'd0; a_col[i] <= 12'd0;
                s_x0[i] <= 5'd0; a_x0[i] <= 5'd0; s_y0[i] <= 5'd0; a_y0[i] <= 5'd0;
                s_x1[i] <= 5'd0; a_x1[i] <= 5'd0; s_y1[i] <= 5'd0; a_y1[i] <= 5'd0;
            end
        end else begin
            // -------- MMIO writes (staging scene) -------------------------------
            if (gpu_we) begin
                case (gpu_addr)
{ctl_write(["for (i = 0; i < 8; i = i + 1) s_en[i] <= 1'b0;"])}
                4'd3: fill_col <= gpu_wdata[11:0];
                4'd4: begin sel_slot <= gpu_wdata[2:0]; sel_vert <= gpu_wdata[4]; end
                4'd5: begin s_en[sel_slot] <= gpu_wdata[4];
                            s_ty[sel_slot] <= gpu_wdata[1:0]; end
                4'd6: s_col[sel_slot] <= gpu_wdata[11:0];
                4'd7: begin
                    if (sel_vert == 1'b0) begin
                        s_x0[sel_slot] <= gpu_wdata[4:0];
                        s_y0[sel_slot] <= gpu_wdata[14:10];
                    end else begin
                        s_x1[sel_slot] <= gpu_wdata[4:0];
                        s_y1[sel_slot] <= gpu_wdata[14:10];
                    end
                    sel_vert <= ~sel_vert;       // auto-increment 0 -> 1 -> 0
                end
                default: ;
                endcase
            end

            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            px_valid    <= 1'b0;

            gpu_rdata <= {{22'd0, frame_done, busy, 3'd0, sy}};

            // -------- the scan ----------------------------------------------------
            case (state)
            S_IDLE: begin
                busy <= 1'b0;
                if (commit_strobe) begin
                    for (i = 0; i < 8; i = i + 1) begin
                        a_en[i] <= s_en[i]; a_ty[i] <= s_ty[i]; a_col[i] <= s_col[i];
                        a_x0[i] <= s_x0[i]; a_y0[i] <= s_y0[i];
                        a_x1[i] <= s_x1[i]; a_y1[i] <= s_y1[i];
                    end
                    busy <= 1'b1; sx <= 5'd0; sy <= 5'd0; state <= S_PIX;
                end
            end
            S_PIX: if (advance && ctl_enable) begin
                px_valid <= 1'b1;
                px_x <= sx; px_y <= sy; px_rgb <= pix_rgb_w;
                if (sx == 5'd0 && sy == 5'd0) frame_start <= 1'b1;
                state <= S_NEXT;
            end
            S_NEXT: begin
                if (sx == 5'd31 && sy == 5'd31) begin
                    frame_done <= 1'b1;
                    if (ctl_cont) begin sx <= 5'd0; sy <= 5'd0; state <= S_PIX; end
                    else          begin state <= S_IDLE; end
                end else begin
                    if (sx == 5'd31) begin sx <= 5'd0; sy <= sy + 5'd1; end
                    else             sx <= sx + 5'd1;
                    state <= S_PIX;
                end
            end
            default: state <= S_IDLE;
            endcase
        end
    end
endmodule
"""
    write(os.path.join(OUT, name + ".v"), hdr + "\n" + body)


# ===========================================================================
#  4) gpu_raster64 -- triangle rasteriser with incremental edge functions
# ===========================================================================

def gen_raster64():
    name = "gpu_raster64"
    hdr = banner(name + ".v", [
        "64x64 MONO triangle rasteriser: 4 triangle slots rendered with",
        "EDGE FUNCTIONS  E(x,y) = A*x + B*y + C  (A = dy, B = -dx).",
        "The Cs are seeded with multiplies ONCE per commit, then the scan",
        "steps them purely incrementally (E += A per pixel, +B per row) --",
        "the exact technique of the flagship GPU.v polygon path. Coverage =",
        "all three edge values share a sign. Row-serial 64-bit scanout.",
    ])
    body = f"""//  {name}: 4 triangle slots on a 64x64 monochrome screen.
//
//  MMIO: gpu_we / gpu_addr[3:0] / gpu_wdata[31:0] -> writes, gpu_rdata reads
{CTL_COMMENT}//   4  SEL      {{ vert_ptr[5:4], slot[1:0] }}
//   5  PRIMHDR  {{ en = bit4 }}
//   7  VERT     {{ y[15:10], x[5:0] }}   3 vertices per slot (ptr 0,1,2;
//                                       auto-increments, wraps at 3)
//   read -> STATUS {{ 22'd0, frame_done, busy, 2'd0, cur_y[5:0] }}
//
//  RENDER MATH (flagship technique):
//    edge k of a triangle (xk,yk) -> (xn,yn):  A = yn-yk, B = -(xn-xk),
//    C = yk*xn - xk*yn.   E(x,y) = A*x + B*y + C  is seeded at (0,0) by a
//    short multiply pass at commit (S_SEED, one edge per cycle); after that
//    the whole frame uses ONLY adds:  E += A stepping x, rowE += B per row.
//    A pixel is inside when E0,E1,E2 are all >= 0 or all <= 0 (winding-
//    independent, edge-inclusive). Disabled slots are operand-isolated.
//
module {name} (
{bus_ports(extra_out=(
    "    output reg         mono_valid,\n"
    "    output reg [5:0]   mono_y,\n"
    "    output reg [63:0]  mono_s0\n"
))});

{DEFINE_BUS}    // define mono_valid   output 24.133.242
    // define mono_y       output 109.109.242
    // define mono_s0      output 255.255.255

{CTL_DECL}
    // ---- scene store: staging + active (4 slots x 3 vertices) ---------------
    reg        s_en [0:3];    reg        a_en [0:3];
    reg [5:0]  s_vx [0:11];   reg [5:0]  a_vx [0:11];   // {{slot,vert}}
    reg [5:0]  s_vy [0:11];   reg [5:0]  a_vy [0:11];
    reg [1:0]  sel_slot;
    reg [1:0]  sel_vert;

{COMMIT_WIRE}
    // ---- edge cells: 4 slots x 3 edges -----------------------------------
    //  e_A/e_B are the per-step increments; e_row is E at the start of the
    //  current row; e_cur is E at the current pixel. 16-bit signed is ample
    //  (|A|,|B| <= 63 ; |C| <= 63*63).
    reg signed [15:0] e_A   [0:11];
    reg signed [15:0] e_B   [0:11];
    reg signed [15:0] e_row [0:11];
    reg signed [15:0] e_cur [0:11];

    // ---- coverage at the current pixel (operand-isolated per slot) ---------
    //  sign test only: no arithmetic on parked slots' values is performed.
    wire [3:0] allp, alln;
    genvar g;
    generate for (g = 0; g < 4; g = g + 1) begin : SGN
        wire s0 = e_cur[g*3+0][15];   // sign bits
        wire s1 = e_cur[g*3+1][15];
        wire s2 = e_cur[g*3+2][15];
        wire z0 = (e_cur[g*3+0] == 16'sd0);
        wire z1 = (e_cur[g*3+1] == 16'sd0);
        wire z2 = (e_cur[g*3+2] == 16'sd0);
        assign allp[g] = a_en[g] & (~s0 | z0) & (~s1 | z1) & (~s2 | z2);
        assign alln[g] = a_en[g] & ( s0 | z0) & ( s1 | z1) & ( s2 | z2);
    end endgenerate
    wire covered = |(allp | alln);
    wire pix_on  = ctl_fill | covered;

    // ---- scan FSM ------------------------------------------------------------
    //  S_SEED: 12 cycles, one edge per cycle, the ONLY multiplies in the design
    //  S_PIX : step x 0..63, shifting pixels into the row register
    //  S_ROW : present the finished row, then add B to every row accumulator
    localparam S_IDLE = 3'd0, S_SEED = 3'd1, S_PIX = 3'd2,
               S_ROW = 3'd3, S_NEXT = 3'd4;
    reg [2:0] state;
    reg [3:0] seed_i;          // 0..11 edge being seeded
    reg [5:0] cur_x, cur_y;
    reg [63:0] rowbits;
    reg busy;
    integer i;

    // seeding helpers: edge seed_i belongs to slot seed_i/3, joins vertex k
    // to vertex (k+1) mod 3
    wire [1:0] sd_slot = (seed_i >= 4'd9) ? 2'd3 :
                         (seed_i >= 4'd6) ? 2'd2 :
                         (seed_i >= 4'd3) ? 2'd1 : 2'd0;
    wire [1:0] sd_k    = (seed_i >= 4'd9) ? (seed_i - 4'd9)
                       : (seed_i >= 4'd6) ? (seed_i - 4'd6)
                       : (seed_i >= 4'd3) ? (seed_i - 4'd3) : seed_i;
    wire [1:0] sd_kn   = (sd_k == 2'd2) ? 2'd0 : (sd_k + 2'd1);
    wire signed [15:0] xk = {{10'd0, a_vx[{{sd_slot, sd_k }}]}};
    wire signed [15:0] yk = {{10'd0, a_vy[{{sd_slot, sd_k }}]}};
    wire signed [15:0] xn = {{10'd0, a_vx[{{sd_slot, sd_kn}}]}};
    wire signed [15:0] yn = {{10'd0, a_vy[{{sd_slot, sd_kn}}]}};

    always @(posedge clk) begin
        if (reset) begin
            ctl_enable <= 1'b0; ctl_fill <= 1'b0; ctl_wait <= 1'b0; ctl_cont <= 1'b0;
            sel_slot <= 2'd0; sel_vert <= 2'd0;
            state <= S_IDLE; busy <= 1'b0; seed_i <= 4'd0;
            cur_x <= 6'd0; cur_y <= 6'd0; rowbits <= 64'd0;
            mono_valid <= 1'b0; mono_y <= 6'd0; mono_s0 <= 64'd0;
            frame_start <= 1'b0; frame_done <= 1'b0; gpu_rdata <= 32'd0;
            for (i = 0; i < 4; i = i + 1) begin s_en[i] <= 1'b0; a_en[i] <= 1'b0; end
            for (i = 0; i < 12; i = i + 1) begin
                s_vx[i] <= 6'd0; a_vx[i] <= 6'd0; s_vy[i] <= 6'd0; a_vy[i] <= 6'd0;
                e_A[i] <= 16'sd0; e_B[i] <= 16'sd0;
                e_row[i] <= 16'sd0; e_cur[i] <= 16'sd0;
            end
        end else begin
            // -------- MMIO writes (staging scene) -------------------------------
            if (gpu_we) begin
                case (gpu_addr)
{ctl_write(["s_en[0] <= 1'b0; s_en[1] <= 1'b0;",
            "s_en[2] <= 1'b0; s_en[3] <= 1'b0;"])}
                4'd4: begin sel_slot <= gpu_wdata[1:0]; sel_vert <= gpu_wdata[5:4]; end
                4'd5: s_en[sel_slot] <= gpu_wdata[4];
                4'd7: begin
                    s_vx[{{sel_slot, sel_vert}}] <= gpu_wdata[5:0];
                    s_vy[{{sel_slot, sel_vert}}] <= gpu_wdata[15:10];
                    sel_vert <= (sel_vert == 2'd2) ? 2'd0 : (sel_vert + 2'd1);
                end
                default: ;
                endcase
            end

            frame_start <= 1'b0;
            frame_done  <= 1'b0;
            mono_valid  <= 1'b0;

            gpu_rdata <= {{22'd0, frame_done, busy, 2'd0, cur_y}};

            case (state)
            S_IDLE: begin
                busy <= 1'b0;
                if (commit_strobe) begin
                    for (i = 0; i < 4; i = i + 1)  a_en[i] <= s_en[i];
                    for (i = 0; i < 12; i = i + 1) begin
                        a_vx[i] <= s_vx[i]; a_vy[i] <= s_vy[i];
                    end
                    busy <= 1'b1; seed_i <= 4'd0; state <= S_SEED;
                end
            end

            // ---- seed pass: the only multiplies, one edge per cycle ---------
            S_SEED: begin
                e_A  [seed_i] <= yn - yk;                 // A =  dy
                e_B  [seed_i] <= xk - xn;                 // B = -dx
                e_row[seed_i] <= yk * xn - xk * yn;       // C = E(0,0)
                e_cur[seed_i] <= yk * xn - xk * yn;
                if (seed_i == 4'd11) begin
                    cur_x <= 6'd0; cur_y <= 6'd0; rowbits <= 64'd0;
                    state <= S_PIX;
                end else seed_i <= seed_i + 4'd1;
            end

            // ---- build one row: pure increments, one pixel per cycle --------
            S_PIX: begin
                rowbits[cur_x] <= pix_on;
                for (i = 0; i < 12; i = i + 1)
                    e_cur[i] <= e_cur[i] + e_A[i];        // E += A  (step x)
                if (cur_x == 6'd63) state <= S_ROW;
                else                cur_x <= cur_x + 6'd1;
            end

            // ---- present the row, advance y ---------------------------------
            S_ROW: if (advance && ctl_enable) begin
                mono_valid <= 1'b1;
                mono_y     <= cur_y;
                mono_s0    <= rowbits;
                if (cur_y == 6'd0) frame_start <= 1'b1;
                for (i = 0; i < 12; i = i + 1) begin
                    e_row[i] <= e_row[i] + e_B[i];        // rowE += B (step y)
                    e_cur[i] <= e_row[i] + e_B[i];
                end
                state <= S_NEXT;
            end
            S_NEXT: begin
                rowbits <= 64'd0; cur_x <= 6'd0;
                if (cur_y == 6'd63) begin
                    frame_done <= 1'b1;
                    if (ctl_cont) begin
                        cur_y <= 6'd0;
                        for (i = 0; i < 12; i = i + 1) begin
                            e_row[i] <= e_row[i] - (e_B[i] <<< 6);  // rewind 64 rows
                            e_cur[i] <= e_row[i] - (e_B[i] <<< 6);
                        end
                        state <= S_PIX;
                    end else state <= S_IDLE;
                end else begin
                    cur_y <= cur_y + 6'd1;
                    state <= S_PIX;
                end
            end
            default: state <= S_IDLE;
            endcase
        end
    end
endmodule
"""
    write(os.path.join(OUT, name + ".v"), hdr + "\n" + body)


# ===========================================================================
#  5) gpu_pipelined32 -- 3-stage pixel pipeline with ppln_* strobes
# ===========================================================================

def gen_pipelined32():
    name = "gpu_pipelined32"
    hdr = banner(name + ".v", [
        "32x32 RGB24 PIPELINED GPU: the scene model of gpu_vector32 pushed",
        "through a 3-STAGE PIXEL PIPELINE (GEN -> EVAL -> COMPOSE), one",
        "pixel in flight per stage. The per-class coverage datapaths are",
        "gated by external PIPELINE SYNCHRONIZER strobes (ppln_point /",
        "ppln_line / ppln_rect -- drive high for normal run), the same",
        "convention as the flagship RV32IM_SYSTEM.v execution units.",
        "screen_ready back-pressure stalls the WHOLE pipe (single pipe_en).",
    ])
    body = f"""//  {name}: 8 slots x {{point | hline | vline | rect}} on 32x32, RGB24,
//  rendered by a 3-stage pixel pipeline:
//
//      GEN ----------> EVAL ----------> COMPOSE
//      coordinate      8 parallel        painter priority,
//      stepper         coverage tests    colour mux, px_* port
//      (sx,sy)         (operand-         (handshake lives here;
//                       isolated)         stall freezes all stages)
//
//  MMIO: gpu_we / gpu_addr[3:0] / gpu_wdata[31:0] -> writes, gpu_rdata reads
{CTL_COMMENT}//   3  FILLCOLOR {{ rgb24[23:0] }}
//   4  SEL      {{ vert_ptr[4], slot[2:0] }}
//   5  PRIMHDR  {{ en = bit4, type[1:0] = bits[1:0] }}
//                type: 00 point | 01 hline | 10 vline | 11 rect
//   6  PRIMCOL  {{ rgb24[23:0] }}
//   7  VERT     {{ y[14:10], x[4:0] }}  vert 0 = origin, vert 1 = extent
//   read -> STATUS {{ 22'd0, frame_done, busy, 3'd0, st1_y[4:0] }}
//
//  PIPELINE SYNCHRONIZERS: gate_class = ppln_class & slot_is_class & slot_en.
//  With a strobe low that class's comparators see all-zero inputs and emit
//  no coverage; drive all three high for normal operation.
//
module {name} (
    input              clk,
    input              reset,
    input              gpu_we,
    input      [3:0]   gpu_addr,
    input      [31:0]  gpu_wdata,
    output reg [31:0]  gpu_rdata,
    // pipeline synchronizer strobes -- drive high for normal run
    input              ppln_point,
    input              ppln_line,
    input              ppln_rect,
    input              screen_ready,
    output reg         frame_start,
    output reg         frame_done,
    output             enable,
    output             fill,
    output reg         px_valid,
    output reg [4:0]   px_x,
    output reg [4:0]   px_y,
    output reg [23:0]  px_rgb
);

{DEFINE_BUS}    // define ppln_point   input  242.24.242
    // define ppln_line    input  242.24.180
    // define ppln_rect    input  242.24.120
    // define px_valid     output 68.213.242
    // define px_x         output 24.242.97
    // define px_y         output 153.15.130
    // define px_rgb       output 255.60.60

{CTL_DECL}
    // ---- scene store: staging + active --------------------------------------
    reg        s_en  [0:7];   reg        a_en  [0:7];
    reg [1:0]  s_ty  [0:7];   reg [1:0]  a_ty  [0:7];
    reg [23:0] s_col [0:7];   reg [23:0] a_col [0:7];
    reg [4:0]  s_x0  [0:7];   reg [4:0]  a_x0  [0:7];
    reg [4:0]  s_y0  [0:7];   reg [4:0]  a_y0  [0:7];
    reg [4:0]  s_x1  [0:7];   reg [4:0]  a_x1  [0:7];
    reg [4:0]  s_y1  [0:7];   reg [4:0]  a_y1  [0:7];
    reg [23:0] fill_col;
    reg [2:0]  sel_slot;
    reg        sel_vert;

{COMMIT_WIRE}
    // =========================================================================
    //  STAGE 1 -- GEN: coordinate stepper
    // =========================================================================
    reg        st1_v;
    reg [4:0]  st1_x, st1_y;
    wire       st1_last = (st1_x == 5'd31) && (st1_y == 5'd31);

    // =========================================================================
    //  STAGE 2 -- EVAL: 8 coverage tests, class datapaths gated by ppln_*
    // =========================================================================
    reg        st2_v;
    reg [4:0]  st2_x, st2_y;
    reg [7:0]  st2_cov;
    reg        st2_first, st2_last;

    wire [7:0] cov_w;
    genvar g;
    generate for (g = 0; g < 8; g = g + 1) begin : COV
        // pipeline synchronizer gating: external strobe AND slot class
        wire is_pt = (a_ty[g] == 2'd0);
        wire is_ln = (a_ty[g] == 2'd1) | (a_ty[g] == 2'd2);
        wire is_rc = (a_ty[g] == 2'd3);
        wire gate  = a_en[g] & ( (is_pt & ppln_point)
                               | (is_ln & ppln_line)
                               | (is_rc & ppln_rect) );
        // operand isolation: comparator inputs forced to zero when gated off
        wire [4:0] gx = st1_x & {{5{{gate}}}};
        wire [4:0] gy = st1_y & {{5{{gate}}}};
        wire xe = (gx == a_x0[g]);
        wire ye = (gy == a_y0[g]);
        wire xr = (gx >= a_x0[g]) & (gx <= a_x1[g]);
        wire yr = (gy >= a_y0[g]) & (gy <= a_y1[g]);
        assign cov_w[g] = gate & (
              (a_ty[g] == 2'd0) ? (xe & ye)
            : (a_ty[g] == 2'd1) ? (ye & xr)
            : (a_ty[g] == 2'd2) ? (xe & yr)
            :                     (xr & yr));
    end endgenerate

    // =========================================================================
    //  STAGE 3 -- COMPOSE: painter priority + output port (handshake here)
    // =========================================================================
    wire [23:0] comp_col =
          st2_cov[7] ? a_col[7] : st2_cov[6] ? a_col[6]
        : st2_cov[5] ? a_col[5] : st2_cov[4] ? a_col[4]
        : st2_cov[3] ? a_col[3] : st2_cov[2] ? a_col[2]
        : st2_cov[1] ? a_col[1] : st2_cov[0] ? a_col[0] : 24'd0;
    wire [23:0] comp_rgb = ctl_fill ? fill_col : comp_col;

    //  back-pressure: the output pixel may only leave when the screen is
    //  ready (or we're free-running); otherwise the WHOLE pipe freezes.
    wire pipe_en = advance | ~px_valid;  // hold ALL stages while the output
                                         // pixel sits unconsumed at the port

    reg busy;
    reg draining;          // frame fully generated, pipe emptying
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            ctl_enable <= 1'b0; ctl_fill <= 1'b0; ctl_wait <= 1'b0; ctl_cont <= 1'b0;
            sel_slot <= 3'd0; sel_vert <= 1'b0; fill_col <= 24'd0;
            busy <= 1'b0; draining <= 1'b0;
            st1_v <= 1'b0; st1_x <= 5'd0; st1_y <= 5'd0;
            st2_v <= 1'b0; st2_x <= 5'd0; st2_y <= 5'd0;
            st2_cov <= 8'd0; st2_first <= 1'b0; st2_last <= 1'b0;
            px_valid <= 1'b0; px_x <= 5'd0; px_y <= 5'd0; px_rgb <= 24'd0;
            frame_start <= 1'b0; frame_done <= 1'b0; gpu_rdata <= 32'd0;
            for (i = 0; i < 8; i = i + 1) begin
                s_en[i] <= 1'b0; a_en[i] <= 1'b0;
                s_ty[i] <= 2'd0; a_ty[i] <= 2'd0;
                s_col[i] <= 24'd0; a_col[i] <= 24'd0;
                s_x0[i] <= 5'd0; a_x0[i] <= 5'd0; s_y0[i] <= 5'd0; a_y0[i] <= 5'd0;
                s_x1[i] <= 5'd0; a_x1[i] <= 5'd0; s_y1[i] <= 5'd0; a_y1[i] <= 5'd0;
            end
        end else begin
            // -------- MMIO writes (staging scene) -------------------------------
            if (gpu_we) begin
                case (gpu_addr)
{ctl_write(["for (i = 0; i < 8; i = i + 1) s_en[i] <= 1'b0;"])}
                4'd3: fill_col <= gpu_wdata[23:0];
                4'd4: begin sel_slot <= gpu_wdata[2:0]; sel_vert <= gpu_wdata[4]; end
                4'd5: begin s_en[sel_slot] <= gpu_wdata[4];
                            s_ty[sel_slot] <= gpu_wdata[1:0]; end
                4'd6: s_col[sel_slot] <= gpu_wdata[23:0];
                4'd7: begin
                    if (sel_vert == 1'b0) begin
                        s_x0[sel_slot] <= gpu_wdata[4:0];
                        s_y0[sel_slot] <= gpu_wdata[14:10];
                    end else begin
                        s_x1[sel_slot] <= gpu_wdata[4:0];
                        s_y1[sel_slot] <= gpu_wdata[14:10];
                    end
                    sel_vert <= ~sel_vert;
                end
                default: ;
                endcase
            end

            frame_start <= 1'b0;
            frame_done  <= 1'b0;

            gpu_rdata <= {{22'd0, frame_done, busy, 3'd0, st1_y}};

            // -------- frame launch ----------------------------------------------
            if (!busy && commit_strobe) begin
                for (i = 0; i < 8; i = i + 1) begin
                    a_en[i] <= s_en[i]; a_ty[i] <= s_ty[i]; a_col[i] <= s_col[i];
                    a_x0[i] <= s_x0[i]; a_y0[i] <= s_y0[i];
                    a_x1[i] <= s_x1[i]; a_y1[i] <= s_y1[i];
                end
                busy <= 1'b1; draining <= 1'b0;
                st1_v <= 1'b1; st1_x <= 5'd0; st1_y <= 5'd0;
                st2_v <= 1'b0; px_valid <= 1'b0;
            end else if (busy && pipe_en && ctl_enable) begin
                // ---- STAGE 3 latches STAGE 2 (output port) ----
                px_valid <= st2_v;
                px_x     <= st2_x;
                px_y     <= st2_y;
                px_rgb   <= comp_rgb;
                if (st2_v && st2_first) frame_start <= 1'b1;
                if (st2_v && st2_last) begin
                    frame_done <= 1'b1;
                    if (ctl_cont) begin           // immediately rescan
                        st1_v <= 1'b1; st1_x <= 5'd0; st1_y <= 5'd0;
                        draining <= 1'b0;
                    end else begin
                        busy <= st1_v | st2_v;    // let the pipe drain
                        draining <= 1'b1;
                    end
                end
                // ---- STAGE 2 latches STAGE 1 (coverage evaluated combinationally
                //      on st1_* this cycle, registered here) ----
                st2_v     <= st1_v;
                st2_x     <= st1_x;
                st2_y     <= st1_y;
                st2_cov   <= cov_w;
                st2_first <= st1_v && (st1_x == 5'd0) && (st1_y == 5'd0);
                st2_last  <= st1_v && st1_last;
                // ---- STAGE 1 steps the coordinates ----
                if (st1_v) begin
                    if (st1_last) st1_v <= 1'b0;          // frame generated
                    else if (st1_x == 5'd31) begin
                        st1_x <= 5'd0; st1_y <= st1_y + 5'd1;
                    end else st1_x <= st1_x + 5'd1;
                end
                if (draining && !st1_v && !st2_v) begin
                    busy <= 1'b0; px_valid <= 1'b0; draining <= 1'b0;
                end
            end else if (busy && !pipe_en) begin
                // stalled: hold everything (px_valid stays asserted so the
                // screen can take the pixel when ready)
            end
        end
    end
endmodule
"""
    write(os.path.join(OUT, name + ".v"), hdr + "\n" + body)


gen_dot8()
gen_sprite16()
gen_vector32()
gen_raster64()
gen_pipelined32()
print("GPUs: dot8 / sprite16 / vector32 / raster64 / pipelined32 generated")
