#!/usr/bin/env python3
# Generates src/games/game_doom3d.v: sine table, per-column ray offsets,
# perspective-divide table, and the 16x16 maze ROM.  The maze below is
# checked for solid borders, open entrance/exit cells, and BFS reachability
# from the entrance (2,2) to the exit (13,13) before anything is written.

import os
_HERE = os.path.dirname(os.path.abspath(__file__))
_TPL  = os.path.join(_HERE, 'doom_template.v')
_OUT  = os.path.join(_HERE, '..', 'src', 'games', 'game_doom3d.v')

import math, collections

# ---------------------------------------------------------------------------
# the maze (X = wall, . = open).  Row 0 is the top (y = 0), column 0 the left.
# Entrance cell (2,2), exit cell (13,13).
# ---------------------------------------------------------------------------
MAZE = [
    "XXXXXXXXXXXXXXXX",  # y = 0
    "X......X.......X",
    "X....X.X.XXXXX.X",
    "X..XXX.X.....X.X",
    "X..X...XXXXX.X.X",
    "X..X.X.....X.X.X",
    "X....XXXXX.X.X.X",
    "XXXX.X...X.X...X",
    "X....X.X.X.XXX.X",
    "X.XXXX.X.X...X.X",
    "X......X.XXX.X.X",
    "X.XXXXXX...X.X.X",
    "X........X.X.X.X",
    "X.XXXXXX.X.....X",
    "X........X.....X",
    "XXXXXXXXXXXXXXXX",  # y = 15
]
START = (2, 2)
EXIT  = (13, 13)

# ---------------------------------------------------------------------------
# maze sanity checks
# ---------------------------------------------------------------------------
assert len(MAZE) == 16 and all(len(r) == 16 for r in MAZE), "maze must be 16x16"
for x in range(16):
    assert MAZE[0][x] == 'X' and MAZE[15][x] == 'X', "top/bottom border open"
for y in range(16):
    assert MAZE[y][0] == 'X' and MAZE[y][15] == 'X', "left/right border open"
assert MAZE[START[1]][START[0]] == '.', "entrance cell is a wall"
assert MAZE[EXIT[1]][EXIT[0]] == '.', "exit cell is a wall"

# BFS from the entrance
seen = {START}
q = collections.deque([(START, 0)])
exit_dist = None
while q:
    (x, y), d = q.popleft()
    if (x, y) == EXIT:
        exit_dist = d
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < 16 and 0 <= ny < 16 and MAZE[ny][nx] == '.' \
                and (nx, ny) not in seen:
            seen.add((nx, ny))
            q.append(((nx, ny), d + 1))
assert exit_dist is not None, "exit not reachable from entrance!"
print("maze OK: exit reachable in %d steps, %d open cells" % (exit_dist, len(seen)))
for y, row in enumerate(MAZE):
    marked = list(row)
    if y == START[1]: marked[START[0]] = 'S'
    if y == EXIT[1]:  marked[EXIT[0]]  = 'E'
    print("   " + "".join(marked))

# ---------------------------------------------------------------------------
# LUT builders
# ---------------------------------------------------------------------------
def tc8(v):
    return v & 0xFF

sin_lines = []
for a in range(256):
    v = int(round(64.0 * math.sin(2.0 * math.pi * a / 256.0)))
    sin_lines.append("      8'h%02X: sinlut = 8'h%02X;  // %4d" % (a, tc8(v), v))
SINLUT = "\n".join(sin_lines)

ofs_lines = []
for c in range(32):
    v = int(round((c - 15.5) * 4.0 / 3.0))
    ofs_lines.append("      5'h%02X: colofs = 8'h%02X;  // %3d" % (c, tc8(v), v))
COLOFS = "\n".join(ofs_lines)

hgt_lines = []
for s in range(256):
    if s == 0:
        v = 15
    else:
        v = max(1, min(15, int(round(112.0 / s))))
    hgt_lines.append("      8'h%02X: hgt = 4'd%d;" % (s, v))
HGT = "\n".join(hgt_lines)

map_lines = []
for y in range(16):
    v = 0
    for x in range(16):
        if MAZE[y][x] == 'X':
            v |= 1 << x
    # binary literal is printed MSB first, i.e. x=15 on the left
    map_lines.append("      4'd%-2d: maprow = 16'b%s;" % (y, format(v, '016b')))
MAPROW = "\n".join(map_lines)

template = open(_TPL).read()
out = (template.replace('@@SINLUT@@', SINLUT)
               .replace('@@COLOFS@@', COLOFS)
               .replace('@@HGT@@', HGT)
               .replace('@@MAPROW@@', MAPROW))
open(_OUT, 'w').write(out)
print("written", len(out.splitlines()), "lines")
