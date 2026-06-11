#!/usr/bin/env bash
# Functional spot-tests for bitfries-logic-layouts.
#
# Each library .v file is self-contained (embeds its own leaf cells), so a test
# concatenates ONE library file with a behavioral-golden testbench and runs it
# under Icarus Verilog. Two files that EMBED the same leaf cells must never be
# concatenated (duplicate-module error) - that is a test-harness constraint,
# not a library limitation.
#
# SYSTEM-LEVEL TESTS: a testbench may declare additional library files with a
# header line  "// FT_ALSO: <path> [<path>...]"  (paths relative to src/).
# This is how the interpreter tests pull in a host CPU and the GPU companion
# rig pulls in the flagship - those files define disjoint module names, so
# concatenation is safe.
#
# This script runs a representative subset: structurally non-trivial modules and
# every sequential block, each against a behavioral golden model. Combinational
# arithmetic is checked exhaustively at 4/8-bit and with corner+random cases at
# 16/32-bit. See the per-test .v files in this directory.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/src"
PASS=0; FAIL=0
run() {  # run <module_file> <testbench_file> [extra library files...]
  local m="$1" tb="$2"; shift 2
  cat "$m" "$@" "$tb" > /tmp/_ft.v
  if iverilog -o /tmp/_ft /tmp/_ft.v 2>/tmp/_ft.err && vvp /tmp/_ft 2>/dev/null | grep -q "0 errors"; then
    echo "  PASS  $(basename "$m" .v)"; PASS=$((PASS+1))
  else
    echo "  FAIL  $(basename "$m" .v)"; FAIL=$((FAIL+1))
  fi
}
echo "Functional tests (golden-model comparison):"
for tb in "$ROOT"/tests/tb_*.v; do
  [ -e "$tb" ] || continue
  mod=$(basename "$tb" | sed 's/^tb_//; s/\.v$//')
  # find the module file
  f=$(find "$SRC" -name "${mod}.v" | head -1)
  extras=""
  for e in $(sed -n 's|^// FT_ALSO: ||p' "$tb"); do extras="$extras $SRC/$e"; done
  [ -n "$f" ] && run "$f" "$tb" $extras
done
echo "----"
echo "functional: $PASS passed, $FAIL failed"
