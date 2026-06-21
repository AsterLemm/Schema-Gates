#!/usr/bin/env python3
# lint_games.py -- static checks for the SchemaGates games family.
#
# iverilog elaboration is the real gate (see tests/games/run_all.sh); this
# linter additionally enforces the *house rules* that a Verilog compiler
# does not care about:
#
#   1. STRUCTURE   module/endmodule, begin/end, case/endcase,
#                  function/endfunction, task/endtask, generate/endgenerate
#                  all balance within every file.
#   2. SELF-CONTAINMENT   every module instantiated with the family's
#                  "u_<name>" instance convention is defined in the same
#                  file (repo rule: files embed all their submodules).
#                  Other instance names (e.g. a testbench's "dut") are
#                  exempt -- those reference a module in another file.
#   3. BANNED TOKENS   game sources may not use '*', '/', '%' or the
#                  'signed' keyword (synthesizer constraint).  '@*' and
#                  '@(*)' sensitivity lists are exempt.  Testbenches are
#                  simulation-only and skip this check.
#   4. PORT DIRECTIVES   every top-module port has a matching
#                  '// define <name> <input|output> <r>.<g>.<b>' header
#                  line and vice versa, directions agree, and the top
#                  module name matches the filename.  Game sources only.
#
# Usage:  python3 scripts/lint_games.py        (from the repo root)
# Exit status 0 = clean, 1 = problems found.

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME_DIR = os.path.join(ROOT, 'src', 'games')
TB_DIR = os.path.join(ROOT, 'tests', 'games')


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
            # keep newlines so line numbers stay meaningful
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


PAIRS = [
    (r'\bmodule\b', r'\bendmodule\b', 'module/endmodule'),
    (r'\bbegin\b', r'\bend\b', 'begin/end'),
    (r'\bcase[xz]?\b', r'\bendcase\b', 'case/endcase'),
    (r'\bfunction\b', r'\bendfunction\b', 'function/endfunction'),
    (r'\btask\b', r'\bendtask\b', 'task/endtask'),
    (r'\bgenerate\b', r'\bendgenerate\b', 'generate/endgenerate'),
]


def check_structure(code, errs):
    for opener, closer, name in PAIRS:
        a = len(re.findall(opener, code))
        b = len(re.findall(closer, code))
        if a != b:
            errs.append('unbalanced %s (%d vs %d)' % (name, a, b))


def check_self_contained(code, errs):
    defined = set(re.findall(r'\bmodule\s+(\w+)', code))
    for mod, inst in re.findall(r'^\s*(\w+)\s+(u_\w+)\s*\(', code, re.M):
        if mod in ('module', 'input', 'output', 'inout', 'wire', 'reg',
                   'assign', 'function', 'task'):
            continue
        if mod not in defined:
            errs.append('instance %s of undefined module "%s" '
                        '(files must be self-contained)' % (inst, mod))
    return defined


def check_banned(code, errs):
    neutral = code.replace('@(*)', '@( )').replace('@*', '@ ')
    for ln, line in enumerate(neutral.split('\n'), 1):
        for tok in ('*', '/', '%'):
            if tok in line:
                errs.append('banned operator "%s" on line %d' % (tok, ln))
        if re.search(r'\bsigned\b', line):
            errs.append('banned keyword "signed" on line %d' % ln)


def check_port_directives(raw, code, fname, errs):
    base = os.path.splitext(os.path.basename(fname))[0]
    m = re.search(r'\bmodule\s+(\w+)\s*\((.*?)\);', code, re.S)
    if not m:
        errs.append('no module header found')
        return
    top, header = m.group(1), m.group(2)
    if top != base:
        errs.append('top module "%s" != filename "%s"' % (top, base))
    ports = {}
    for d, name in re.findall(
            r'\b(input|output)\s+(?:wire|reg)?\s*(?:\[[^\]]*\])?\s*(\w+)',
            header):
        ports[name] = d
    defines = {}
    for d_name, d_dir in re.findall(
            r'^//\s*define\s+(\w+)\s+(input|output)\s+\d+\.\d+\.\d+\s*$',
            raw, re.M):
        defines[d_name] = d_dir
    for p, d in sorted(ports.items()):
        if p not in defines:
            errs.append('port "%s" has no // define directive' % p)
        elif defines[p] != d:
            errs.append('port "%s" direction mismatch: module says %s, '
                        'directive says %s' % (p, d, defines[p]))
    for p in sorted(defines):
        if p not in ports:
            errs.append('// define for "%s" but no such top-level port' % p)


def lint_file(path, strict):
    raw = open(path).read()
    code = strip_comments_and_strings(raw)
    errs = []
    check_structure(code, errs)
    defined = check_self_contained(code, errs)
    if strict:
        check_banned(code, errs)
        check_port_directives(raw, code, path, errs)
    n_inst = len(re.findall(r'^\s*\w+\s+u_\w+\s*\(', code, re.M))
    return errs, len(defined), n_inst


def main():
    failed = 0
    groups = [(GAME_DIR, True), (TB_DIR, False)]
    for d, strict in groups:
        if not os.path.isdir(d):
            continue
        for f in sorted(os.listdir(d)):
            if not f.endswith('.v') or f.endswith('_template.v'):
                continue
            path = os.path.join(d, f)
            errs, nmod, ninst = lint_file(path, strict)
            rel = os.path.relpath(path, ROOT)
            if errs:
                failed += 1
                print('LINT-FAIL %s' % rel)
                for e in errs:
                    print('    - %s' % e)
            else:
                print('ok        %s  (%d modules, %d u_ instances%s)'
                      % (rel, nmod, ninst,
                         '' if strict else ', testbench rules'))
    print('-' * 60)
    if failed:
        print('lint: %d file(s) FAILED' % failed)
        return 1
    print('lint: all clean')
    return 0


if __name__ == '__main__':
    sys.exit(main())
