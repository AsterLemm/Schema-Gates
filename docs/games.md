# The games family

Twelve self-contained Verilog-2001 game modules that share one display
convention (the pixel bus below), one button-conditioning idiom and one
top-level port style, so any of them can be dropped into a SchemaGates
layout -- or any other harness -- the same way.  Each game lives in a
single file under `src/games/` and has a self-checking testbench under
`tests/games/` (`sh tests/games/run_all.sh` runs them all).

## The pixel bus

Every displayed game drives the same six signals:

| signal     | dir | meaning                                               |
|------------|-----|-------------------------------------------------------|
| `px_x`     | out | column of the pixel being driven (width fits screen)  |
| `px_y`     | out | row of the pixel being driven                         |
| `px_en`    | out | 1 = light the pixel at (`px_x`,`px_y`)                |
| `px_clear` | out | 1-cycle pulse: blank the whole display                |
| `px_fill`  | out | 1-cycle pulse: set the whole display (effects only)   |
| `frame`    | out | pulses once per frame, on the clear/fill cycle        |

The contract, frame by frame: the module emits a single `px_clear` cycle
(the attached display blanks), then sweeps the whole screen row-major,
asserting `px_en` on every pixel that should be lit.  The display latches
pixels between clears, so anything not re-lit on the next sweep
disappears then.  `px_fill` replaces `px_clear` on frames that flash the
whole screen (explosions, muzzle flash, win celebration); `px_clear` and
`px_fill` are never high together, `px_en` is never high on the
clear/fill cycle, and `frame == px_clear | px_fill` always.  Everything
is gated by `en`: with `en` low the raster, the game logic and all four
strobes freeze.

For the fixed-rate games one frame is exactly `W*H + 1` clocks (the
sweep plus the clear cycle).  `game_doom3d` is the one exception: it
casts its 32 view rays *between* sweeps, so its frames have a variable
length -- the previous image simply stays latched while the next one is
computed.  Harnesses should sync on the `frame` pulse, never on a clock
count.

## The roster

| module             | screen   | clocks/frame | one-liner                                |
|--------------------|----------|--------------|------------------------------------------|
| `game_snake`       | 16x16    | 257          | snake on a walled field, eat and grow     |
| `game_life16`      | 16x16    | 257          | Conway's Life on a 16x16 torus            |
| `game_tetris`      | 12x22    | 265          | falling tetrominoes in a drawn well       |
| `game_tictactoe`   | 24x24    | 577          | two-player tic-tac-toe, shared cursor     |
| `game_rps`         | 40x24    | 961          | rock-paper-scissors vs the machine        |
| `game_minesweeper` | 32x32    | 1025         | 8x8 board, 10 mines, safe first reveal    |
| `game_doom3d`      | 32x32    | variable     | first-person raycast walk of a 16x16 maze |
| `game_flappy_boat` | 64x32    | 2049         | one-button boat through pillar gaps       |
| `game_pong`        | 64x48    | 3073         | two paddles, first to 7, optional CPU     |
| `game_chess`       | 64x64    | 4097         | two-player chess, lite rules              |
| `game_rps_lite`    | none     | n/a          | rps with one-hot lamp outputs, no raster  |
| `game_tictactoe_lite` | none  | n/a          | tic-tac-toe as bit-vector outputs         |

## Controls and status, per game

All buttons are raw asynchronous inputs: each module conditions them
internally with a 2-flop synchroniser plus rising-edge pulse
(`game_btn`).  Tap buttons act on the press edge; the doom walk/turn
buttons are *held* levels, sampled once per frame.

- **game_snake** -- `btn_up/down/left/right` steer (180-degree reversals
  ignored), `btn_new` restarts, `speed[1:0]` 0 slowest .. 3 a move every
  frame.  Status: `o_len[6:0]`, `o_over`, `o_win`.
- **game_life16** -- `btn_run` toggles auto-evolve at `speed[1:0]`,
  `btn_step` single-steps, `btn_rand` reseeds, `btn_clear` wipes,
  `btn_up/down/left/right` move the edit cursor and `btn_toggle` flips
  the cell under it.  Status: `o_pop[8:0]`, `o_gen[15:0]`, `o_running`.
- **game_tetris** -- `btn_left/right` shift, `btn_rot` rotates CW,
  `btn_down` soft-drops while held, `btn_drop` hard-drops, `btn_new`
  restarts, `speed[1:0]` sets gravity.  Status: `o_lines[7:0]`,
  `o_pieces[7:0]`, `o_next[2:0]`, `o_over`.
- **game_tictactoe** -- `btn_up/down/left/right` move the shared cursor,
  `btn_place` drops the mark, `btn_new` restarts.  Status:
  `o_board[17:0]` (2 bits per cell), `o_turn`, `o_win`, `o_winner`,
  `o_draw`.
- **game_rps** -- `btn_rock/paper/scissors` throw, `btn_new` clears the
  score.  Status: `o_player[1:0]`, `o_cpu[1:0]`, `o_result[1:0]`,
  `o_score_p[3:0]`, `o_score_c[3:0]`.
- **game_minesweeper** -- `btn_up/down/left/right` move the cell cursor
  (wraps), `btn_reveal` digs (the first reveal is always safe -- mines
  scatter after it), `btn_flag` toggles a flag, `btn_new` re-deals.
  Status: `o_flags[3:0]`, `o_boom`, `o_win`.
- **game_doom3d** -- hold `btn_fwd`/`btn_back` to walk (1/4 cell per
  frame, walls slide), hold `btn_left`/`btn_right` to turn (2/256 of a
  turn per frame), `btn_fire` flashes one frame, `btn_new` returns to
  the entrance.  Reach cell (13,13) to win.  Status: `o_posx[11:0]`,
  `o_posy[11:0]` (4.8 fixed point, cell = bits [11:8]), `o_ang[7:0]`
  (256 units per revolution, 0 = +x), `o_win`.
- **game_flappy_boat** -- `btn_flap` hops the boat (and starts a run),
  `btn_new` resets.  Status: `o_score[7:0]`, `o_dead`, `o_playing`.
- **game_pong** -- `btn_p1_up/dn` drive the left paddle, `btn_p2_up/dn`
  the right one unless `cpu_p2` is high (the machine tracks the ball),
  `btn_new` restarts after game over.  First to 7.  Status: `o_s1[2:0]`,
  `o_s2[2:0]`, `o_over`, `o_winner`.
- **game_chess** -- `btn_up/down/left/right` move the shared cursor
  (wraps), `btn_sel` selects one of your pieces / deselects on the
  source / reselects on another of yours / moves if the destination is
  legal (illegal ones are ignored), `btn_new` re-racks.  Lite rules:
  movement, blocking, captures and auto-queening are enforced; no
  check, castling or en passant -- capture the king to win.  Status:
  `o_turn`, `o_over`, `o_winner`, `o_sel`, `o_src[5:0]`,
  `o_cursor[5:0]` (both pack `{y,x}`), `o_piece[3:0]`
  (`{colour, type}`; type 0 empty, 1 pawn, 2 knight, 3 bishop, 4 rook,
  5 queen, 6 king; colour 0 white).

## The lite variants

`game_rps_lite` and `game_tictactoe_lite` play identically to their big
siblings but have **no pixel bus at all**: every bit of game state is a
direct output (one-hot throw/result lamps for rps; 9-bit X / O / cursor /
winning-line vectors for tic-tac-toe).  They exist for layouts where you
wire outputs straight to indicators instead of a display, and as the
smallest possible integration test of the family conventions.

## Integration notes

- **Self-contained files.**  Every module a game uses (`game_btn`,
  `game_sync2`, LFSRs, ...) is embedded in its own file; the duplication
  across files is intentional.  One file = one drop-in game.
- **Standard front matter.**  Each file starts with a header comment
  block including `// define <port> input|output R.G.B` colour
  directives for the SchemaGates importer, and generated sections are
  bracketed with `BITF_*` markers.
- **Verilog-2001, synthesis-friendly subset.**  No `*`, `/` or `%`
  operators anywhere (multiplies are shift/add, divides are LUTs),
  synchronous active-high `rst`, a global `en` that freezes everything,
  and 2-flop synchronisers on every raw button.
- **Generated games.**  `game_rps`, `game_tetris`, `game_minesweeper`,
  `game_doom3d` and `game_chess` are emitted by `scripts/gen_game_*.py`
  from the matching `scripts/*_template.v`; edit the generator or the
  template, not the output file.
- **Checks.**  `scripts/lint_games.py` enforces the file conventions;
  `scripts/check_tb_ports.py` cross-checks every testbench instantiation
  against its DUT's port list; `tests/games/run_all.sh` runs all the
  benches under Icarus Verilog (`-g2001`).
