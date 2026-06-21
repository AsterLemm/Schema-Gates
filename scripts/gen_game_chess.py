#!/usr/bin/env python3
# Generates src/games/game_chess.v.  The six piece glyphs are defined once as
# filled 8x8 ASCII art (the black set); the white set is derived
# automatically as the outline: every filled pixel that touches an empty
# 4-neighbour (or the glyph edge) stays, interior pixels are hollowed out.
# Row byte bit x = pixel at column x (bit 0 = leftmost pixel on screen).

import os
_HERE = os.path.dirname(os.path.abspath(__file__))
_TPL  = os.path.join(_HERE, 'chess_template.v')
_OUT  = os.path.join(_HERE, '..', 'src', 'games', 'game_chess.v')

PIECES = {
    1: ("pawn",   ["........",
                   "........",
                   "...XX...",
                   "...XX...",
                   "..XXXX..",
                   "..XXXX..",
                   ".XXXXXX.",
                   "........"]),
    2: ("knight", ["........",
                   "..XXX...",
                   ".XXXXX..",
                   "XXX.XX..",
                   "....XX..",
                   "...XXX..",
                   "..XXXXX.",
                   "........"]),
    3: ("bishop", ["........",
                   "...X....",
                   "..XXX...",
                   ".XXXXX..",
                   "..XXX...",
                   "..XXX...",
                   ".XXXXXX.",
                   "........"]),
    4: ("rook",   ["........",
                   ".X.XX.X.",
                   ".XXXXXX.",
                   "..XXXX..",
                   "..XXXX..",
                   "..XXXX..",
                   ".XXXXXX.",
                   "........"]),
    5: ("queen",  ["........",
                   "X..XX..X",
                   "X.XXXX.X",
                   ".XXXXXX.",
                   "..XXXX..",
                   "..XXXX..",
                   ".XXXXXX.",
                   "........"]),
    6: ("king",   ["...XX...",
                   "..XXXX..",
                   "...XX...",
                   "..XXXX..",
                   ".XXXXXX.",
                   ".XXXXXX.",
                   ".XXXXXX.",
                   "........"]),
}

def cells(rows):
    return [[1 if rows[y][x] == 'X' else 0 for x in range(8)] for y in range(8)]

def outline(c):
    o = [[0] * 8 for _ in range(8)]
    for y in range(8):
        for x in range(8):
            if not c[y][x]:
                continue
            edge = False
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < 8 and 0 <= ny < 8) or not c[ny][nx]:
                    edge = True
            o[y][x] = 1 if edge else 0
    return o

def rowbyte(c, y):
    v = 0
    for x in range(8):
        if c[y][x]:
            v |= 1 << x
    return v

def emit(name, sets):
    lines = []
    for t in range(1, 7):
        pname, rows = PIECES[t]
        c = sets[t]
        lines.append("      // %s" % pname)
        for y in range(8):
            sel = (t << 3) | y
            lines.append("      6'h%02X: %s = 8'h%02X;" % (sel, name, rowbyte(c, y)))
    return "\n".join(lines)

filled = {t: cells(PIECES[t][1]) for t in PIECES}
hollow = {t: outline(filled[t]) for t in PIECES}

GLYPHB = emit("glyph_b", filled)
GLYPHW = emit("glyph_w", hollow)

# round-trip sanity print: black (solid) and white (outline) side by side
for t in range(1, 7):
    pname = PIECES[t][0]
    print("%s:" % pname)
    for y in range(8):
        b = "".join('X' if filled[t][y][x] else '.' for x in range(8))
        w = "".join('X' if hollow[t][y][x] else '.' for x in range(8))
        print("   %s   %s" % (b, w))
    print()

template = open(_TPL).read()
out = template.replace('@@GLYPHW@@', GLYPHW).replace('@@GLYPHB@@', GLYPHB)
open(_OUT, 'w').write(out)
print("written", len(out.splitlines()), "lines")
