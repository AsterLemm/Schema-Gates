#!/usr/bin/env python3
# Generates src/games/game_rps.v.  The four 16x16 glyphs (rock, paper,
# scissors, unknown) are defined as ASCII art below and emitted as a
# 64-entry BITF_LUT (sel = {glyph[1:0], row[3:0]}).
# Row bit i = pixel at local x = i (bit 0 = leftmost pixel).

import os
_HERE = os.path.dirname(os.path.abspath(__file__))
_TPL  = os.path.join(_HERE, 'rps_template.v')
_OUT  = os.path.join(_HERE, '..', 'src', 'games', 'game_rps.v')

GLYPHS = {
    0: ("rock", [
        "................",
        "................",
        ".....XXXXXX.....",
        "...XX......XX...",
        "..X..........X..",
        ".X.....X......X.",
        ".X....X.X.....X.",
        "X....X...X.....X",
        "X...X.....X....X",
        "X..........X...X",
        "X...........X..X",
        ".X...........XX.",
        ".X............X.",
        "..XX........XX..",
        "....XXXXXXXX....",
        "................"]),
    1: ("paper", [
        "...XXXXXXX......",
        "...X.....XX.....",
        "...X.....X.X....",
        "...X.....XXXX...",
        "...X........X...",
        "...X.XXXXXX.X...",
        "...X........X...",
        "...X.XXXX...X...",
        "...X........X...",
        "...X.XXXXXX.X...",
        "...X........X...",
        "...X.XXXXX..X...",
        "...X........X...",
        "...XXXXXXXXXX...",
        "................",
        "................"]),
    2: ("scissors", [
        "...X........X...",
        "....X......X....",
        "....X......X....",
        ".....X....X.....",
        ".....X....X.....",
        "......X..X......",
        "......X..X......",
        ".......XX.......",
        ".......XX.......",
        "......X..X......",
        "....XXX..XXX....",
        "...X..X..X..X...",
        "...X..X..X..X...",
        "...X..X..X..X...",
        "....XX....XX....",
        "................"]),
    3: ("unknown", [
        "................",
        ".....XXXXXX.....",
        "....X......X....",
        "...........X....",
        "..........X.....",
        ".........X......",
        "........X.......",
        ".......XX.......",
        ".......XX.......",
        "................",
        "................",
        ".......XX.......",
        ".......XX.......",
        "................",
        "................",
        "................"]),
}

def to_bits(row):
    v = 0
    for x in range(16):
        if row[x] == 'X':
            v |= 1 << x
    return v

lut_lines = []
for g in range(4):
    name, rows = GLYPHS[g]
    assert len(rows) == 16, name
    for r in rows:
        assert len(r) == 16, (name, r)
    lut_lines.append("        // glyph %d: %s" % (g, name))
    for y in range(16):
        sel = (g << 4) | y
        lut_lines.append("        6'h%02X: glyph_row = 16'h%04X;"
                         % (sel, to_bits(rows[y])))
LUT = "\n".join(lut_lines)

# round-trip sanity print
for g in range(4):
    name, rows = GLYPHS[g]
    print(name + ":")
    for y in range(16):
        v = to_bits(rows[y])
        print("   " + "".join('X' if (v >> x) & 1 else '.' for x in range(16)))
    print()

template = open(_TPL).read()
out = template.replace('@@LUT@@', LUT)
open(_OUT, 'w').write(out)
print("written", len(out.splitlines()), "lines")
