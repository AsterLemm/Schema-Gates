# GPUs

Five display processors forming a difficulty ladder up to the hand-written
flagship `GPU`, all speaking the same MMIO bus, the same CONTROL register,
and the same racing-the-beam philosophy: **there is no framebuffer
anywhere** -- pixels are computed in scan order and handed to the display
through a ready handshake.

*Directory:* `src/GPUs/` -- 11 modules (5 generated GPUs, 1 hand-maintained
flagship, 5 hand-maintained companions).

| Module | Screen | Scene | Scanout | The lesson |
|--------|--------|-------|---------|------------|
| `gpu_dot8` | 8×8 mono | 4 point slots | row-serial | the whole contract at minimum size |
| `gpu_sprite16` | 16×16 MUX(4b) | 4 sprite stamps (8×8, 1bpp) | pixel-serial | stamps, transparency, painter priority |
| `gpu_vector32` | 32×32 RGB12 | 8× point/hline/vline/rect | pixel-serial | multi-primitive coverage tests |
| `gpu_raster64` | 64×64 mono | 4 triangles | row-serial (64-bit) | incremental edge functions |
| `gpu_pipelined32` | 32×32 RGB24 | 8× point/hline/vline/rect | pixel-serial, 3-stage pipe | pipelining + ppln strobes + back-pressure |
| `GPU` | up to 256×256 / 32×32 colour | 4 slots, 2D+3D polygons | row- or pixel-serial | the flagship; hand-maintained, not generated |

## Shared bus and CONTROL register

```
writes : gpu_we / gpu_addr[3:0] / gpu_wdata[31:0]
reads  : gpu_rdata[31:0]   (STATUS, registered every cycle)

CONTROL (gpu_addr 1):
  bit 0  enable            display only draws while high
  bit 1  fill              flood the screen with FILLCOLOR
  bit 2  scene_clear*      clear all staging slot enables
  bit 3  wait_for_screen   gate the scan on screen_ready
  bit 4  commit*           latch staging scene -> active, start a frame
  bit 5  continuous        re-scan forever after frame_done
                           (* = self-clearing strobe)
```

Identical bit positions to the flagship, so driver code ports across the
whole family. The remaining registers follow the flagship map where the
design has the feature: `3 FILLCOLOR`, `4 SEL` (slot + auto-incrementing
vertex/row pointer), `5 PRIMHDR` (enable always at bit 4), `6 PRIMCOL`,
`7 VERT` (x in the low field, y at bits [1x:10]). `gpu_sprite16` adds
`9 STAMPROW` for stamp bitmap rows.

**Double-buffered scenes:** register writes land in a *staging* copy;
`commit` flips staging into the *active* copy between frames. You can
build the next scene while the current one is still scanning out --
tear-free by construction.

**Handshake:** with `wait_for_screen=1` the scan advances only on
`screen_ready` (true valid/ready flow control); with it clear the GPU
free-runs one step per clock and you slow the clock instead.
`frame_start` / `frame_done` pulse at the scan boundaries. STATUS reads
back `{frame_done, busy, scan position}`.

**Operand isolation:** every per-slot coverage comparator has its inputs
ANDed with the slot enable (and, in `gpu_pipelined32`, with the class
strobe), so parked slots hold constant zeros -- in the schematic viewer the
live primitives visibly light their compare trees.

## Screen interfaces

Monochrome designs present **rows**: `mono_valid`, `mono_y`, and a row
bitmap (`mono_row[7:0]` on dot8, `mono_s0[63:0]` on raster64 -- the
flagship's slice-0 naming). Colour designs present **pixels**:
`px_valid`, `px_x`, `px_y`, plus `px_mux[3:0]` (sprite16) or
`px_rgb[23:0]` (vector32 / pipelined32; RGB12 sources nibble-expand each
channel exactly like the flagship).

## gpu_dot8

The "hello world": four enabled points OR onto each row as it scans.
Start here to learn the bus; `tests/tb_gpu_dot8.v` is a complete driver
session (program, commit, capture, re-commit with a slot disabled).

## gpu_sprite16

Each slot is an 8×8 one-bit stamp with a 4-bit colour and a free (x,y).
Stamp rows load through `STAMPROW` at `SEL.row_ptr` (auto-increments, so
eight consecutive writes fill a stamp). Coverage subtracts the sprite
origin from the scan position and indexes the stamp; zero stamp bits are
transparent. Higher slots paint over lower ones.

## gpu_vector32

Eight slots, each `point | hline | vline | rect` (PRIMHDR type bits) with
its own RGB12 colour. `VERT` writes vertex 0 (origin) then vertex 1
(extent, inclusive) via the auto-toggling `SEL.vert_ptr`. Coverage per
slot is a pair of range compares; the painter mux takes the highest
covering slot.

## gpu_raster64 -- incremental edge functions

The flagship's triangle mathematics in isolation. For each edge from
(xk,yk) to (xn,yn):

```
A = yn - yk          (dE/dx)
B = -(xn - xk)       (dE/dy)
C = yk*xn - xk*yn    = E(0,0)
E(x,y) = A*x + B*y + C
```

At commit, a 12-cycle `S_SEED` pass computes the three `C`s per slot --
**the only multiplies in the design**. From then on the whole frame is
adds: stepping x does `E += A` on all twelve edge cells in parallel;
finishing a row does `rowE += B` and reloads the cells. A pixel is covered
when a slot's three edge values are all ≥ 0 or all ≤ 0 (winding-
independent, edge-inclusive -- `tests/tb_gpu_raster64.v` renders the same
triangle in both windings and counts identical pixels, ~726 for an
area-700 triangle). Rows assemble in a 64-bit register and present once
complete, so the handshake stays row-granular while the math is
pixel-granular.

`continuous` mode rewinds the row accumulators by `B<<6` instead of
re-seeding -- animation without ever touching the multipliers again.

## gpu_pipelined32 -- the pixel pipeline

The vector32 scene model restructured as three registered stages:

```
GEN      st1: coordinate stepper (sx,sy)
EVAL     st2: 8 coverage tests in parallel, operand-isolated
COMPOSE  out: painter priority, colour mux, px_* port
```

One pixel occupies each stage; throughput is one pixel per clock when the
screen keeps up. Back-pressure is a single `pipe_en`: while the output
pixel sits unconsumed (`px_valid` high, `screen_ready` low under
`wait_for_screen`), **all three stages freeze** -- nothing is dropped or
duplicated, which `tests/tb_gpu_pipelined32.v` proves by scanning a frame
under randomized `screen_ready` and checking all 1024 pixels arrive
strictly in order.

The EVAL classes are gated by external **pipeline synchronizer** strobes
exactly like the flagship CPU's execution units: `gate = ppln_class &
slot_is_class & slot_en` with `ppln_point / ppln_line / ppln_rect` input
pins (hline+vline share `ppln_line`). Tie them high to run; drop one and
that class is operand-isolated out of the frame (also covered by the
testbench).

## Companions

Five hand-maintained peripherals that speak the family's bus and screen
contracts (verified against the real flagship by `tests/tb_gpu_scene_player.v`
and the per-module golden tests):

| Module | Role |
|--------|------|
| `gpu_frame_pacer` | programmable `screen_ready` heartbeat (rate 0 = held high, N = one pulse every N+1 clocks) plus frame counter, `frame_tick`, and an `in_frame` window |
| `gpu_row_to_pixel` | mono ROW interface (all four 64-bit slices) -> PIXEL-serial stream with valid/ready on both sides; lets mono GPUs drive pixel consumers such as the CRC below |
| `gpu_scene_player` | standalone MMIO driver with an embedded command script: configures the flagship, loads a 3D filled triangle, then bumps ROT and re-commits at every `frame_done` - animation with no CPU anywhere |
| `gpu_frame_crc32` | per-frame CRC-32 (poly 04C11DB7, MSB-first) over accepted pixels, latched at `frame_done` - framebuffer-free rendering verification; rotating scenes produce changing signatures, frozen scenes repeat them exactly |
| `gpu_mmio_arbiter2` | two write masters (CPU + player) on one GPU register bus, fixed A-priority, with a `b_dropped` flag making any displaced write observable |

Typical standalone rig: `gpu_scene_player` -> bus, `gpu_frame_pacer` ->
`screen_ready`, `gpu_frame_crc32` tapping `px_*`. The golden test runs it
against the actual flagship: every pixel of every frame accepted exactly
once, distinct signatures while rotating, identical signatures with the
rotation step set to 0.

## Flagship: GPU

`src/GPUs/GPU.v` is the hand-written flagship: configurable geometry up to
256×256, four colour modes, a 4-slot scene store of 2D **and 3D**
primitives (points/lines/polygons with rotation + ortho/isometric
projection, four shared multipliers in the transform pass), filled/outline
polygons via the same edge functions as `gpu_raster64`, and both screen
interfaces. It is **not** produced by a generator; edit it directly.

**Handshake rule (fixed in this revision):** the presenting states consume
`screen_ready` only when the *registered* `px_valid` / `mono_valid` is
already visible outside (`advance && px_valid`). Without that qualifier, a
ready pulse landing on the presentation cycle itself stepped the scan past
pixel (0,0) before it was ever shown - re-committed frames silently
delivered 1023/1024 pixels. The companion rig above is what exposed it.
