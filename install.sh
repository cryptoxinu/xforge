#!/bin/bash
# xforge installer — forge battle-tested CLAUDE.md files
# https://github.com/cryptoxinu/xforge

set -e

SKILL_DIR="$HOME/.claude/skills/xforge"

echo "Installing xforge..."
mkdir -p "$SKILL_DIR"

if command -v curl &> /dev/null; then
    curl -fsSL https://raw.githubusercontent.com/cryptoxinu/xforge/main/SKILL.md -o "$SKILL_DIR/SKILL.md"
elif command -v wget &> /dev/null; then
    wget -qO "$SKILL_DIR/SKILL.md" https://raw.githubusercontent.com/cryptoxinu/xforge/main/SKILL.md
else
    echo "Error: curl or wget required"
    exit 1
fi

echo "Installed to $SKILL_DIR/SKILL.md"
echo "Run /xforge in any Claude Code session to get started."
