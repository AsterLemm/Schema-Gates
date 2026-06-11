#!/usr/bin/env python3
# Generates src/games/game_minesweeper.v.  The neighbour-count glyphs for
# counts 1..8 are dice-style dot patterns on the 3x3 cell core, defined as
# ASCII art below and emitted as a 9-entry BITF_LUT.
# Bitmap bit index = 3*ly + lx, bit 0 = top-left dot.

import os
_HERE = os.path.dirname(os.path.abspath(__file__))
_TPL  = os.path.join(_HERE, 'mines_template.v')
_OUT  = os.path.join(_HERE, '..', 'src', 'games', 'game_minesweeper.v')

DOTS = {
    1: ["...",
        ".X.",
        "..."],
    2: ["X..",
        "...",
        "..X"],
    3: ["X..",
        ".X.",
        "..X"],
    4: ["X.X",
        "...",
        "X.X"],
    5: ["X.X",
        ".X.",
        "X.X"],
    6: ["X.X",
        "X.X",
        "X.X"],
    7: ["X.X",
        "XXX",
        "X.X"],
    8: ["XXX",
        "X.X",
        "XXX"],
}

def to_bits(rows):
    v = 0
    for y in range(3):
        for x in range(3):
            if rows[y][x] == 'X':
                v |= 1 << (3 * y + x)
    return v

lut_lines = []
for n in range(1, 9):
    v = to_bits(DOTS[n])
    lut_lines.append("      4'd%d: dots = 9'b%s;" % (n, format(v, '09b')))
LUT = "\n".join(lut_lines)

# round-trip sanity print
for n in range(1, 9):
    v = to_bits(DOTS[n])
    print("%d:" % n)
    for y in range(3):
        print("   " + "".join('X' if (v >> (3 * y + x)) & 1 else '.'
                              for x in range(3)))

template = open(_TPL).read()
out = template.replace('@@DOTS@@', LUT)
open(_OUT, 'w').write(out)
print("written", len(out.splitlines()), "lines")
