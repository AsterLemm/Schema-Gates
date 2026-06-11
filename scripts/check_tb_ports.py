#!/usr/bin/env python3
# check_tb_ports.py -- static TB <-> DUT cross-checks for the games family.
#
# iverilog elaboration is still the real gate (tests/games/run_all.sh); this
# script catches the most common breakage *without* a simulator installed:
#
#   1. Every tb_game_X.v instantiates module game_X with named port
#      connections, and the set of connected ports == the DUT's port list
#      (no missing ports, no unknown ports).
#   2. Every signal the TB connects exists as a reg/wire declared in the TB.
#   3. Declared TB vector widths match the DUT port widths.
#   4. No Verilog-2001 reserved word is used as an identifier anywhere
#      (the `cell` trap: legal in many tools, rejected by iverilog -g2001).
#
# Usage:  python3 scripts/check_tb_ports.py        (from the repo root)
# Exit status 0 = clean, 1 = problems found.

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME_DIR = os.path.join(ROOT, 'src', 'games')
TB_DIR = os.path.join(ROOT, 'tests', 'games')

RESERVED = set("""
always and assign automatic begin buf bufif0 bufif1 case casex casez cell
cmos config deassign default defparam design disable edge else end endcase
endconfig endfunction endgenerate endmodule endprimitive endspecify endtable
endtask event for force forever fork function generate genvar highz0 highz1
if ifnone incdir include initial inout input instance integer join large
liblist library localparam macromodule medium module nand negedge nmos nor
noshowcancelled not notif0 notif1 or output parameter pmos posedge primitive
pull0 pull1 pulldown pullup pulsestyle_onevent pulsestyle_ondetect rcmos
real realtime reg release repeat rnmos rpmos rtran rtranif0 rtranif1
scalared showcancelled signed small specify specparam strong0 strong1
supply0 supply1 table task time tran tranif0 tranif1 tri tri0 tri1 triand
trior trireg unsigned use uwire vectored wait wand weak0 weak1 while wire
wor xnor xor
""".split())

# words that legitimately appear as keywords in the sources; flag only when
# used as an *identifier* (declaration, port, instance, or function name)
# Names in a declaration list must not swallow the *next* declaration's
# keyword (ANSI port lists chain "name,\n  input ..." across lines), so the
# continuation excludes declaration-introducing keywords only.  Reserved
# words outside this small set (e.g. `cell`, `table`) ARE captured -- and
# then flagged.
_KW = r'(?:input|output|inout|wire|reg|signed|integer|genvar|localparam|parameter)'
_NAME = r'(?!' + _KW + r'\b)[A-Za-z_][\w$]*'
DECL_RE = re.compile(
    r'\b(?:input|output|inout|reg|wire|integer|genvar|localparam|parameter)\b'
    r'(?:\s+(?:wire|reg|signed|integer))?\s*(?:\[[^\]]*\]\s*)?'
    r'(' + _NAME + r'(?:\s*,\s*' + _NAME + r')*)')
FUNC_RE = re.compile(r'\bfunction\b(?:\s*\[[^\]]*\])?\s+([A-Za-z_][\w$]*)')
TASK_RE = re.compile(r'\btask\b\s+([A-Za-z_][\w$]*)')


def strip_comments_and_strings(text):
    out = []
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if c == '/' and i + 1 < n and text[i + 1] == '/':
            j = text.find('\n', i)
            i = n if j < 0 else j
        elif c == '/' and i + 1 < n and text[i + 1] == '*':
            j = text.find('*/', i + 2)
            seg = text[i:(n if j < 0 else j + 2)]
            out.append('\n' * seg.count('\n'))
            i = n if j < 0 else j + 2
        elif c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == '\\' else 1
            out.append('""')
            i = min(j + 1, n)
        else:
            out.append(c)
            i += 1
    return ''.join(out)


def width_of(rng):
    """'[8:0]' -> 9, '' -> 1.  Non-constant ranges return None (skip)."""
    if not rng:
        return 1
    m = re.match(r'\[\s*(\d+)\s*:\s*(\d+)\s*\]', rng)
    if not m:
        return None
    a, b = int(m.group(1)), int(m.group(2))
    return abs(a - b) + 1


def parse_module_ports(text, modname):
    """Return {port: (dir, width)} for the ANSI-style header of modname."""
    m = re.search(r'\bmodule\s+%s\s*\((.*?)\)\s*;' % re.escape(modname),
                  text, re.S)
    if not m:
        return None
    ports = {}
    body = m.group(1)
    for pm in re.finditer(
            r'\b(input|output|inout)\b\s*(?:wire|reg)?\s*'
            r'(\[[^\]]*\])?\s*([A-Za-z_][\w$]*)', body):
        ports[pm.group(3)] = (pm.group(1), width_of(pm.group(2) or ''))
    return ports


def parse_decls(text):
    """Return {name: width} of every reg/wire/integer declared in the TB."""
    decls = {}
    for dm in re.finditer(
            r'\b(reg|wire|integer)\b\s*(\[[^\]]*\])?\s*'
            r'([A-Za-z_][\w$]*(?:\s*=\s*[^,;]+)?'
            r'(?:\s*,\s*[A-Za-z_][\w$]*(?:\s*=\s*[^,;]+)?)*)\s*;', text):
        kind, rng, names = dm.groups()
        w = 32 if kind == 'integer' else width_of(rng or '')
        for piece in names.split(','):
            name = piece.split('=')[0].strip()
            if name:
                decls[name] = w
    return decls


def parse_instance(text, modname):
    """Return {port: signal} for the named instantiation of modname."""
    m = re.search(r'\b%s\s+(\w+)\s*\((.*?)\)\s*;' % re.escape(modname),
                  text, re.S)
    if not m:
        return None, None
    conns = {}
    for cm in re.finditer(r'\.([A-Za-z_][\w$]*)\s*\(\s*([^)]*?)\s*\)',
                          m.group(2)):
        conns[cm.group(1)] = cm.group(2)
    return m.group(1), conns


def reserved_identifier_hits(text, path):
    hits = []
    for rx in (DECL_RE, FUNC_RE, TASK_RE):
        for m in rx.finditer(text):
            for name in re.split(r'\s*,\s*', m.group(1)):
                name = name.strip()
                if name in RESERVED:
                    line = text.count('\n', 0, m.start()) + 1
                    hits.append('%s:%d: reserved word used as identifier: '
                                '%r' % (path, line, name))
    return hits


def main():
    problems = []
    tbs = sorted(f for f in os.listdir(TB_DIR)
                 if f.startswith('tb_') and f.endswith('.v'))
    for tb in tbs:
        game = tb[3:]                      # tb_game_x.v -> game_x.v
        dut_path = os.path.join(GAME_DIR, game)
        tb_path = os.path.join(TB_DIR, tb)
        tag = 'tests/games/' + tb
        if not os.path.exists(dut_path):
            problems.append('%s: no matching DUT src/games/%s' % (tag, game))
            continue
        dut_text = strip_comments_and_strings(open(dut_path).read())
        tb_text = strip_comments_and_strings(open(tb_path).read())
        modname = game[:-2]
        ports = parse_module_ports(dut_text, modname)
        if ports is None:
            problems.append('%s: cannot parse module %s header'
                            % ('src/games/' + game, modname))
            continue
        inst, conns = parse_instance(tb_text, modname)
        if conns is None:
            problems.append('%s: no instantiation of %s found' % (tag, modname))
            continue
        missing = sorted(set(ports) - set(conns))
        unknown = sorted(set(conns) - set(ports))
        for p in missing:
            problems.append('%s: DUT port %r not connected' % (tag, p))
        for p in unknown:
            problems.append('%s: connects unknown port %r' % (tag, p))
        decls = parse_decls(tb_text)
        for port, sig in conns.items():
            base = re.match(r'([A-Za-z_][\w$]*)', sig)
            if not base:
                continue                   # constant / concat: skip
            name = base.group(1)
            if re.match(r"^\d|^\d*'", sig):
                continue                   # literal
            if name not in decls:
                problems.append('%s: port .%s(%s) -- %r not declared in TB'
                                % (tag, port, sig, name))
                continue
            if sig == name and ports[port][1] is not None \
                    and decls[name] is not None \
                    and decls[name] != ports[port][1]:
                problems.append(
                    '%s: width mismatch on .%s -- DUT %d bits, TB %r %d bits'
                    % (tag, port, ports[port][1], name, decls[name]))
        problems += reserved_identifier_hits(tb_text, tag)
        if not any(p.startswith(tag) for p in problems):
            print('ok        %s  (dut=%s, inst=%s, %d ports)'
                  % (tag, modname, inst, len(ports)))
    for g in sorted(os.listdir(GAME_DIR)):
        if g.endswith('.v'):
            text = strip_comments_and_strings(
                open(os.path.join(GAME_DIR, g)).read())
            problems += reserved_identifier_hits(text, 'src/games/' + g)
    print('-' * 60)
    if problems:
        for p in problems:
            print('PROBLEM   ' + p)
        print('check_tb_ports: %d problem(s)' % len(problems))
        return 1
    print('check_tb_ports: all clean')
    return 0


if __name__ == '__main__':
    sys.exit(main())
