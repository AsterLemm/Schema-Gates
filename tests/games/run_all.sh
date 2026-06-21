#!/bin/sh
# ============================================================================
# run_all.sh -- build and run every games-family testbench
# ----------------------------------------------------------------------------
# Usage (from anywhere):
#   sh tests/games/run_all.sh
# Needs iverilog/vvp on PATH.  Each tests/games/tb_game_X.v is compiled
# with -g2001 against src/games/game_X.v and run; a bench passes when its
# verdict line reads "PASS: tb_game_X (0 errors)" (the last PASS:/FAIL:
# line vvp prints).  Exits 0 only if every bench compiles and passes.
# ============================================================================
set -u
cd "$(dirname "$0")/../.." || exit 1     # repo root, so the paths below work

pass=0
fail=0
for t in tests/games/tb_*.v; do
  g="src/games/$(basename "$t" | sed 's/^tb_//')"
  name="$(basename "$t" .v)"
  if [ ! -f "$g" ]; then
    echo "FAIL: $name (no DUT $g)"
    fail=$((fail + 1))
    continue
  fi
  if ! iverilog -g2001 -o /tmp/schema_games_tb "$t" "$g"; then
    echo "FAIL: $name (compile)"
    fail=$((fail + 1))
    continue
  fi
  out="$(vvp /tmp/schema_games_tb | grep -E '^(PASS|FAIL):' | tail -1)"
  echo "$out"
  case "$out" in
    PASS:*) pass=$((pass + 1)) ;;
    *)      fail=$((fail + 1)) ;;
  esac
done

echo "----------------------------------------"
echo "run_all: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
