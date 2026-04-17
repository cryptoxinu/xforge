#!/usr/bin/env bash
# xforge installer — forge battle-tested CLAUDE.md instruction architectures
# https://github.com/cryptoxinu/xforge
#
# Environment variables:
#   XFORGE_REF  — git ref to install from (tag, commit SHA, or branch). Default: main
#
# Installs:
#   - skill files → ~/.claude/skills/xforge/
#   - commands    → ~/.claude/commands/ (xforge-score.md, xforge-new.md)
#
# Existing installs are backed up with a timestamp before overwrite.

set -euo pipefail

REPO_URL="https://github.com/cryptoxinu/xforge.git"
XFORGE_REF="${XFORGE_REF:-main}"
SKILL_DIR="$HOME/.claude/skills/xforge"
CMD_DIR="$HOME/.claude/commands"
TS=$(date +%Y%m%d-%H%M%S)

command -v git >/dev/null 2>&1 || { echo "error: git is required" >&2; exit 1; }

# Warn about mutable refs
case "$XFORGE_REF" in
  main|master|HEAD)
    echo "Warning: installing from mutable ref '${XFORGE_REF}'."
    echo "  For reproducible installs, pin to a tag or commit SHA:"
    echo "    XFORGE_REF=v3.0.0 bash install.sh"
    echo "    XFORGE_REF=82f9c0a bash install.sh"
    echo ""
    ;;
  *)
    echo "Installing xforge @ ${XFORGE_REF}"
    ;;
esac

# Backup existing installs
if [[ -d "$SKILL_DIR" ]]; then
  BACKUP="${SKILL_DIR}.backup.${TS}"
  echo "Backing up existing skill install → ${BACKUP}"
  mv "$SKILL_DIR" "$BACKUP"
fi
for f in xforge-score.md xforge-new.md; do
  if [[ -f "$CMD_DIR/$f" ]]; then
    mv "$CMD_DIR/$f" "$CMD_DIR/${f}.backup.${TS}"
  fi
done

# Shallow-clone at the requested ref to a temp dir
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
echo "Fetching xforge @ ${XFORGE_REF}..."

# For tag/branch: git clone --branch. For commit SHA: clone + checkout.
if git ls-remote --exit-code "$REPO_URL" "refs/tags/${XFORGE_REF}" >/dev/null 2>&1 || \
   git ls-remote --exit-code "$REPO_URL" "refs/heads/${XFORGE_REF}" >/dev/null 2>&1; then
  git clone --depth 1 --branch "$XFORGE_REF" --quiet "$REPO_URL" "$TMP/xforge"
else
  # Assume commit SHA — can't shallow clone a bare SHA, do normal clone then checkout
  git clone --quiet "$REPO_URL" "$TMP/xforge"
  git -C "$TMP/xforge" checkout --quiet "$XFORGE_REF" || {
    echo "error: '${XFORGE_REF}' is not a valid tag, branch, or commit SHA" >&2
    exit 1
  }
fi

# Record the installed commit SHA for provenance
INSTALLED_SHA=$(git -C "$TMP/xforge" rev-parse HEAD)

# Atomic install into place
mkdir -p "$SKILL_DIR" "$CMD_DIR"
cp -R "$TMP/xforge/SKILL.md"   "$SKILL_DIR/"
cp -R "$TMP/xforge/references" "$SKILL_DIR/"
cp -R "$TMP/xforge/scripts"    "$SKILL_DIR/"
cp -R "$TMP/xforge/examples"   "$SKILL_DIR/"
chmod +x "$SKILL_DIR"/scripts/*.sh 2>/dev/null || true
echo "$INSTALLED_SHA" > "$SKILL_DIR/.installed-commit"

cp "$TMP/xforge/commands/xforge-score.md" "$CMD_DIR/"
cp "$TMP/xforge/commands/xforge-new.md"   "$CMD_DIR/"

echo ""
echo "xforge installed:"
echo "  skill:    $SKILL_DIR (commit: ${INSTALLED_SHA:0:8})"
echo "  commands: $CMD_DIR/xforge-score.md, xforge-new.md"
echo ""
echo "Try it:"
echo "  /xforge score   # read-only health check"
echo "  /xforge         # full pipeline (diff-gated)"
echo "  /xforge new     # generate from scratch"
echo ""
echo "Pin a version for reproducible installs:"
echo "  XFORGE_REF=v3.0.0 bash install.sh"
