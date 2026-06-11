#!/bin/bash
# Bulk-verify: every .v file must elaborate with its top == filename.
fail=0
total=0
for f in $(find src -name '*.v' | sort); do
  top=$(basename "$f" .v)
  total=$((total+1))
  if ! iverilog -t null -s "$top" "$f" 2>/tmp/err; then
    echo "FAIL(elab) $f"; sed 's/^/      /' /tmp/err; fail=$((fail+1))
  fi
done
echo "-------------------------------------------"
echo "elaborated: $((total-fail))/$total   failures: $fail"
