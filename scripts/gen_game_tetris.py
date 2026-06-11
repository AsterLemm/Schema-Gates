#!/usr/bin/env python3
# Generates src/games/game_tetris.v.  The 7 tetromino shapes are defined as
# ASCII 4x4 boxes below; all 4 clockwise rotations are computed and emitted
# as a 28-entry BITF_LUT (sel = {type[2:0], rot[1:0]}).
# Bitmap bit index = (ry << 2) | rx, bit 0 = top-left cell.

import os
_HERE = os.path.dirname(os.path.abspath(__file__))
_TPL  = os.path.join(_HERE, 'tetris_template.v')
_OUT  = os.path.join(_HERE, '..', 'src', 'games', 'game_tetris.v')

SHAPES = {
    0: ("I", [".....",
              "XXXX",
              "....",
              "...."][1:]),
}

SHAPES = {
    0: ("I", ["....",
              "XXXX",
              "....",
              "...."]),
    1: ("O", [".XX.",
              ".XX.",
              "....",
              "...."]),
    2: ("T", [".X..",
              "XXX.",
              "....",
              "...."]),
    3: ("S", [".XX.",
              "XX..",
              "....",
              "...."]),
    4: ("Z", ["XX..",
              ".XX.",
              "....",
              "...."]),
    5: ("J", ["X...",
              "XXX.",
              "....",
              "...."]),
    6: ("L", ["..X.",
              "XXX.",
              "....",
              "...."]),
}

def to_cells(rows):
    return [[1 if rows[y][x] == 'X' else 0 for x in range(4)] for y in range(4)]

def rot_cw(c):
    return [[c[3 - x][y] for x in range(4)] for y in range(4)]

def to_bits(c):
    v = 0
    for y in range(4):
        for x in range(4):
            if c[y][x]:
                v |= 1 << ((y << 2) | x)
    return v

lut_lines = []
for t in range(7):
    name, rows = SHAPES[t]
    c = to_cells(rows)
    lut_lines.append("      // piece %d: %s" % (t, name))
    for r in range(4):
        sel = (t << 2) | r
        lut_lines.append("      5'h%02X: mino = 16'h%04X;" % (sel, to_bits(c)))
        c = rot_cw(c)
LUT = "\n".join(lut_lines)

# round-trip sanity print
for t in range(7):
    name, rows = SHAPES[t]
    c = to_cells(rows)
    arts = []
    for r in range(4):
        v = to_bits(c)
        art = []
        for y in range(4):
            art.append("".join('X' if (v >> ((y << 2) | x)) & 1 else '.'
                               for x in range(4)))
        arts.append(art)
        c = rot_cw(c)
    print(name + ":")
    for y in range(4):
        print("   " + "   ".join(a[y] for a in arts))
    print()

template = open(_TPL).read()
out = template.replace('@@LUT@@', LUT)
open(_OUT, 'w').write(out)
print("written", len(out.splitlines()), "lines")
