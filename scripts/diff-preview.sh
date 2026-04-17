#!/usr/bin/env bash
# Side-by-side diff preview for xforge. Takes two file paths (original, proposed)
# and emits a unified diff with line counts.
# Usage: diff-preview.sh <original> <proposed>

set +e

orig=${1:?"usage: diff-preview.sh <original> <proposed>"}
prop=${2:?"usage: diff-preview.sh <original> <proposed>"}

[[ ! -f $orig ]] && { echo "[xforge:diff] original not found: $orig"; exit 0; }
[[ ! -f $prop ]] && { echo "[xforge:diff] proposed not found: $prop"; exit 0; }

orig_lines=$(wc -l < "$orig" | tr -d ' ')
prop_lines=$(wc -l < "$prop" | tr -d ' ')
delta=$((prop_lines - orig_lines))

echo "=== xforge diff preview ==="
echo "Original: $orig ($orig_lines lines)"
echo "Proposed: $prop ($prop_lines lines)"
echo "Delta: $delta lines"
echo ""
echo "--- Unified diff (context=3) ---"
diff -u "$orig" "$prop"
echo ""
echo "=== end diff preview ==="
