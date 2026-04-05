#!/bin/bash
# xforge installer — forge battle-tested CLAUDE.md instruction architectures
# https://github.com/cryptoxinu/xforge
#
# Environment variables:
#   XFORGE_REF     — git ref to install from (tag, commit, branch). Default: main
#   XFORGE_SHA256  — expected SHA-256 of SKILL.md for checksum verification (optional)

set -euo pipefail

XFORGE_REF="${XFORGE_REF:-main}"
SKILL_DIR="$HOME/.claude/skills/xforge"
RAW_URL="https://raw.githubusercontent.com/cryptoxinu/xforge/${XFORGE_REF}/SKILL.md"
TMPFILE=""

cleanup() { [ -n "${TMPFILE:-}" ] && rm -f "$TMPFILE"; }
trap cleanup EXIT

# Warn about mutable refs
case "$XFORGE_REF" in
  main|master|HEAD)
    echo "Warning: installing from mutable ref '${XFORGE_REF}'."
    echo "  For reproducible installs, pin to a tag or commit:"
    echo "  XFORGE_REF=v1.0.0 bash install.sh"
    echo ""
    ;;
  *)
    echo "Installing xforge @ ${XFORGE_REF}"
    ;;
esac

mkdir -p "$SKILL_DIR"

# Download to a temporary file first
TMPFILE="$(mktemp "${SKILL_DIR}/SKILL.md.XXXXXX")"

if command -v curl &>/dev/null; then
  curl -fsSL "$RAW_URL" -o "$TMPFILE"
elif command -v wget &>/dev/null; then
  wget -qO "$TMPFILE" "$RAW_URL"
else
  echo "Error: curl or wget required" >&2
  exit 1
fi

# Verify the download is not empty
if [ ! -s "$TMPFILE" ]; then
  echo "Error: downloaded file is empty — check XFORGE_REF='${XFORGE_REF}'" >&2
  exit 1
fi

# Optional SHA-256 verification
if [ -n "${XFORGE_SHA256:-}" ]; then
  if command -v sha256sum &>/dev/null; then
    ACTUAL="$(sha256sum "$TMPFILE" | cut -d' ' -f1)"
  elif command -v shasum &>/dev/null; then
    ACTUAL="$(shasum -a 256 "$TMPFILE" | cut -d' ' -f1)"
  else
    echo "Warning: sha256sum/shasum not found — skipping checksum" >&2
    ACTUAL="$XFORGE_SHA256"
  fi

  if [ "$ACTUAL" != "$XFORGE_SHA256" ]; then
    echo "Checksum mismatch!" >&2
    echo "  Expected: $XFORGE_SHA256" >&2
    echo "  Actual:   $ACTUAL" >&2
    exit 1
  fi
  echo "Checksum verified."
fi

# Atomic move into place
mv -f "$TMPFILE" "${SKILL_DIR}/SKILL.md"
TMPFILE=""

echo "Installed to ${SKILL_DIR}/SKILL.md"
echo "Run /xforge in any Claude Code session to get started."
