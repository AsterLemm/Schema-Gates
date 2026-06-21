# Schema Gates

Schema Gates isn educational Verilog logic-gate layout library with built-in
HTML-based schematic viewer. It is a synthesis product of the **BITF-Synth Engine** 
which converts a custom implementation of Verilog into a single-file HTML schematic 
viewer. 

The library has 1140 modules across 29 families, every file follows under Icarus Verilog.
Contains modules with bit widths 4/8/16/32 for primitive logic gates, various types 
of adders/sub, multipliers, dividers, display drivers, etc. Also includes complete CPUs 
(six architectures x five widths), GPUs (five designs plus a 2D/3D flagship), cross-ISA 
interpreters that run one architecture's binaries on another family's CPU, and a games 
family with twelve playable titles: snake, chess, raycast maze, and others, all driving 
one shared pixel bus.

Each core is verified against the corresponding `*`/`/` golden, a meaningful test 
mainly because the device under test contains no such operator (exhaustive at 4/8-bit 
where simulation-feasible, bounded random for 16/32-bit).

## Conventions

1. **One module family member per file**, filename == top module name == catalog name
   (e.g. `add_rc8.v` → module `add_rc8`).
2. **Each `.v` file is fully self-contained**: it embeds copies of every submodule it
   uses, down to leaf gates. Load any single file into SchemaGates and it works, no
   manual combining. Duplication across files is intentional.
3. **Concrete widths, no public parameters**: real `add_rc4/8/16/32`, never `add_rc#(W)`.
4. **Hierarchy preserved** for the viewer (`add_rc32 → add_rc16 → ... → full_adder → half_adder`).
5. **Standard port names**: adders `a,b,cin,sum,cout`; subtractors `a,b,bin,diff,bout`;
   mux `d0..,sel,y`; comparators `a,b → eq/lt/gt/...`; sequential `clk,rst,en,d,q`.
6. **SchemaGates directives**: `// define <port> input|output R.G.B` for top-level I/O
   colouring; `// BITF_LUT` / `// BITF_DECODER` are the synthesizer's functional
   keywords and are kept verbatim (they are the tool's parse contract).

## Layout

```
src/
  primitives/            basic gates, constants, bus join/split, reductions,
                         NAND-only / NOR-only educational cells
  mux_decoder_encoder/   N:1 muxes (1..32 wide), demuxes, decoders(+en),
                         encoders, priority encoders(+valid), one-hot converters
  comparators/           eq/neq, signed+unsigned lt/lte/gt/gte, detectors, flags
  adders/                cells, ripple, CLA, prefix (Kogge-Stone, Brent-Kung,
                         Sklansky, Ladner-Fischer, Han-Carlson, Knowles, sparse-KS),
                         Ling, block-CLA, carry-skip/select, conditional-sum,
                         carry-increment, carry-save, serial, and special adders
  subtractors/           borrow-ripple, two's-complement (ripple/CLA/skip/select/
                         prefix), add/sub units, negate, abs, sign/zero extend
  shifters/              barrel L/R/bidir, logical/arithmetic shifts, rotators
  bit_manipulation/      reverse, masks, set/clear/toggle/extract/insert, swaps
  popcount_bitscan/      popcount, leading/trailing zero/one count, first/last one
  converters/            Gray, one's/two's/sign-magnitude, thermometer, excess/bias
  sequential/            latches, flip-flops, registers, shift registers
  counters/              up/down/updown, ring, Johnson, Gray, mod-N, LFSR, timer,
                         PWM, clock dividers, edge detectors, debouncer
  multipliers/           partial products, array/Braun/carry-save, Wallace/Dadda,
                         Booth radix-2/4/8, Baugh-Wooley, signed, square, const, MAC
  alu_datapath/          logic/arith/full ALUs with flags, PC, IR, SP, accumulator
  dividers/              restoring/non-restoring (comb + iterative), signed, SRT,
                         modulo, reciprocal, Newton-Raphson, Goldschmidt
  sqrt_reciprocal/       integer sqrt (comb + iterative + Newton), reciprocal-sqrt
  bcd/                   binary<->BCD (double-dabble), BCD add/sub, validity, 9's comp
  display/               binary/BCD to 7-segment, ASCII digit conversion
  lut_rom_pla/           LUTs (BITF_LUT), ROMs, decoder-ROM (BITF_DECODER),
                         RAM, PLA, PAL
  memory/                register files (1W/2R, RISC r0=0), dual-port RAM, CAM
  error_detection/       parity, Hamming SEC (7/4 + generic), CRC, checksums
  sorting/               min/max/compare-swap, median, sort networks, bitonic
  dsp/                   fixed-point Q-format add/sub/mul/round/saturate, FIR, CORDIC
  floating_point/        fp8/fp16 pack/unpack/classify/compare/add/sub/mul/div,
                         normalize, round, int<->fp16
  interfaces/            UART tx/rx/baud, SPI master/slave, I2C, parallel<->serial,
                         handshake, synchronous FIFO
  demos/                 worked example circuits wiring blocks together
  CPUs/                  six architecture families x widths 4/8/16/32/64
                         (von Neumann, RV-lite single-cycle + 5-stage pipelined,
                         x86-flavoured CISC, ARM-flavoured, stack machine) and
                         the hand-written RV32IM_SYSTEM flagship
  GPUs/                  racing-the-beam display processors: dot8, sprite16,
                         vector32, raster64 (edge-function triangles),
                         pipelined32 (3-stage pixel pipe), the hand-written
                         2D/3D flagship GPU, and five companions (frame pacer,
                         row->pixel adapter, CPU-less scene player, per-frame
                         CRC-32 signature analyzer, 2-master bus arbiter)
  interpreters/          cross-ISA fetch-path translators: run vN/ARM binaries
                         on the x86 CPU and x86/RISC-V binaries on the ARM CPU
                         without modifying either design; plus native/translated
                         fetch switches ("convert the CPU without rebuilding")
  games/                 twelve playable games on a shared pixel bus: snake,
                         Life, tetris, tic-tac-toe(+lite), rps(+lite), mine-
                         sweeper, doom3d raycaster, flappy boat, pong, chess
scripts/                 Python generators that EMIT clean concrete files
  build_all.py           regenerate the whole library
  verify.sh              bulk elaboration check
  gen_game_*.py          regenerate the 5 template-driven games
  lint_games.py          games-family convention linter
  check_tb_ports.py      games TB <-> DUT port cross-checker
tests/                   functional golden-model benches + run_functional_tests.sh;
                         tests/games/ holds the 12 self-checking game benches
                         and their runner, run_all.sh
docs/                    per-family reference notes (games provenance lives in
                         docs/games-status.md)
SchemaGates/             per-family schematic-viewer HTML exports
```

## Building & verifying

```sh
python3 scripts/build_all.py     # regenerate every generated file
                                 # (the two flagship files are hand-maintained)
./scripts/verify.sh              # elaborate every file (iverilog -t null)
sh tests/games/run_all.sh        # run the 12 self-checking game benches
```

`verify.sh` elaborates each file with Icarus Verilog (`iverilog -t null`, top ==
filename). Functional testbenches check logic against behavioral golden models,
4-bit exhaustive, 8-bit exhaustive where cheap, 16/32-bit via corner + randomized
cases. Sequential blocks are checked with clocked testbenches.

## Status by family (all verified, 0 elaboration errors)

| # | Family | Files | Notes |
|---|--------|-------|-------|
| 1 | primitives | 65 | universal NAND/NOR cells exhaustively tested |
| 2 | mux/decoder/encoder | 64 | mux trees, priority encoders, one-hot |
| 3 | comparators | 88 | signed compare, borrow, overflow flags |
| 4 | adders | 114 | all prefix topologies verified vs serial-prefix + exhaustive 8-bit |
| 5 | subtractors | 66 | two's-complement on every adder core |
| 6 | multipliers | 94 | array/Wallace/Booth-signed/square/const verified |
| 7 | dividers | 64 | signed division verified near-exhaustively |
| 8 | sqrt/reciprocal | 16 | comb + iterative sqrt give correct floor roots |
| 9 | shifters + bit-manip | 73 | structural barrel shifters verified |
| 10 | popcount/bit-scan | 32 | popcount, lzc/tzc, power-of-two |
| 11 | converters | 42 | Gray roundtrip, thermometer, sign-magnitude |
| 12-14 | BCD + display | 37 | double-dabble + decimal-correction add/sub exhaustive |
| 15 | LUT/ROM/PLA | 29 | BITF_LUT (×5) + BITF_DECODER (×2) verbatim |
| 16 | sequential | 56 | latches, flip-flops, registers, shift registers |
| 17 | counters | 61 | ring/Johnson/Gray/mod-N/LFSR/timer/PWM |
| 18 | memory | 9 | register files, dual-port RAM, CAM |
| 19 | ALU/datapath | 52 | full ALU + flags, datapath blocks verified |
| 20 | error detection | 34 | Hamming SEC corrects all single-bit errors; CRC ser==par |
| 21 | sorting | 23 | sort networks + bitonic verified (sorted + permutation) |
| 22 | DSP | 17 | fixed-point Q-format, FIR, CORDIC rotation verified |
| 23 | floating-point | 18 | fp16 add/mul match real reference; int<->fp16 exact |
| 24 | interfaces | 16 | UART loopback, FIFO order, ser/par loopback verified |
| 25 | demos | 10 | traffic-light FSM, tiny CPU, stopwatch verified |
| 26 | CPUs | 31 | six ISAs x five widths + flagship; program suites verified (loops, hazards, flag quirks, cond-exec, stack spill) |
| 27 | GPUs | 11 | five designs + flagship + five companions; scanout verified incl. triangle rasterisation, pipeline back-pressure, and a CPU-less player/pacer/CRC rig against the flagship |
| 28 | interpreters | 6 | guest programs verified on real host CPUs: ARM loop/cond-exec/BL on x86, x86 fib with CALL/RET on ARM, RV loop/SLT/x0-invariant on ARM, plus trap checks |
| 29 | games | 12 | twelve playable games on one shared pixel bus; all 12 self-checking benches pass under iverilog 12.0, conventions machine-checked by lint_games.py / check_tb_ports.py; provenance in docs/games-status.md |
| | **Total** | **1140** | |





