# xforge

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude_Code-skill-6B4FBB.svg)](https://code.claude.com/docs/en/skills)
[![Anthropic Docs](https://img.shields.io/badge/Based_on-Official_Docs-orange.svg)](https://code.claude.com/docs/en/best-practices)

**Your CLAUDE.md sucks. xforge fixes it.**

Most CLAUDE.md files are either bloated junk drawers that Claude ignores, or empty files that do nothing. xforge audits yours, scores it, tells you what's wrong, and generates a replacement that Claude actually follows — with hooks that enforce the rules Claude can't be trusted to follow on its own.

---

## What is this

xforge is a [Claude Code skill](https://code.claude.com/docs/en/skills). You install it once, then run `/xforge` inside any Claude Code session. It:

1. **Scans your project** — detects stack, build commands, test runners, existing rules
2. **Audits for staleness** — validates file paths, commands, and patterns against the live codebase
3. **Scores your CLAUDE.md** — grades A through F across 10 criteria, classifies every line, recommends where each rule belongs
4. **Generates a replacement** — lean root file + scoped rules + hooks + settings, all wired up
5. **Installs everything** — CLAUDE.md, `.claude/rules/`, `.claude/settings.json` hooks, permission deny rules, sandbox config, staleness prevention — one "write it" and you're done

It's not a linter. It's not a template. It's a system that decides where every instruction belongs and puts it there.

### What's new in v2

- **Staleness detection** — validates that file paths, build commands, and code patterns in your CLAUDE.md still exist in the actual codebase. Flags dead references before they mislead Claude
- **Staleness prevention hook** — installs a SessionStart hook that warns when your CLAUDE.md drifts from the codebase (commit distance + config file changes)
- **10-criteria scoring** (was 8) — added Freshness and Layer Architecture criteria
- **Clarifying questions** — for complex domain projects, xforge asks about protected invariants, non-obvious architecture, and repeated Claude mistakes before generating
- **Sandbox configuration** — installs sandbox profiles (strict or permissive) with clear explanation of what each setting does
- **Multi-layer architecture for complex systems** — explicit guidance for projects needing 300+ lines of total instruction across root + rules + skills + hooks
- **Compaction safety** — generated CLAUDE.md includes instructions to preserve critical state during context compaction
- **Violation-to-hook upgrade pattern** — detects rules Claude repeatedly ignores and recommends converting them to deterministic hooks

## Why

Anthropic's own docs say CLAUDE.md instructions are **advisory** — Claude follows them most of the time, but not always, and compliance drops as the file gets longer. The fix isn't a longer file with more rules. The fix is:

- A **short, high-signal root file** (under 200 lines) where every line earns its place
- **Scoped rules** in `.claude/rules/` that only load when relevant
- **Hooks** that deterministically enforce what prose cannot (test gates, format-on-save, push confirmation)
- **Skills** for heavy workflows that don't need to load every session

xforge builds all four layers for you.

## Commands

```
/xforge score   Read-only. Staleness audit + grade + 10-criteria breakdown + placement analysis. Changes nothing.
/xforge         Full pipeline. Backup → staleness audit → score → generate → install. Asks before writing.
/xforge new     Fresh start. Generate full instruction architecture from scratch for the current project.
```

When there's no project CLAUDE.md, xforge targets `~/.claude/CLAUDE.md` instead.

## What it generates

```
your-project/
  CLAUDE.md                          # Lean root file — always-on rules only
  CLAUDE.local.md                    # Your personal/machine-specific notes (gitignored)
  .claude/
    rules/
      api-conventions.md             # Scoped to src/api/** — loads only when relevant
      security.md                    # Cross-cutting — loads every session
    skills/
      deploy/SKILL.md                # Heavy deploy workflow — /deploy to invoke
    settings.json                    # Hooks + permissions + sandbox config
    hooks/
      check-staleness.sh             # Warns on session start when CLAUDE.md drifts
      pre-push-check.sh             # Script-based hook for complex logic
```

### Where each rule goes

| Layer | File | Loads | Use for |
|---|---|---|---|
| Root | `CLAUDE.md` | Always | Verification commands, anti-slop, planning, project boundary, git safety |
| Rules | `.claude/rules/*.md` | Always or path-scoped | Domain policies, module-specific conventions |
| Skills | `.claude/skills/*/SKILL.md` | On demand (`/command`) | Deploy, migrate, audit, compliance workflows |
| Hooks | `.claude/settings.json` | On trigger (deterministic) | Format-on-save, test gate, push confirmation |
| Local | `CLAUDE.local.md` | Always (gitignored) | Local ports, personal preferences, WIP notes |

## What it fixes

**Claude skips stuff** — You ask for 5 things, it does 3 and says "done." xforge generates rules that force Claude to plan first, track every requirement, and verify completeness before claiming done.

**Claude bloats code** — Adds unnecessary abstractions, speculative error handling, docstrings on code it didn't change. xforge generates anti-bloat rules: do exactly what was asked, no more, no less.

**Claude doesn't plan** — Starts coding after reading the first sentence of your prompt. xforge makes Claude automatically present a plan and wait for approval before writing any code. You don't have to ask for it.

**Claude says "done" but nothing works** — Tests pass but the feature isn't wired up. xforge generates wiring verification rules (prove the full data path) AND a Stop hook that blocks completion when tests fail.

**Claude ignores your CLAUDE.md** — Because it's 300 lines of vague garbage. xforge keeps the root file lean and moves overflow to layers Claude actually reads.

**Claude invents new patterns** — Ignores existing codebase conventions and makes up its own. xforge generates rules that force Claude to read existing code and match patterns exactly.

**Your CLAUDE.md is stale** — You wrote it 3 months and 200 commits ago. Build commands changed, files moved, patterns were refactored — but your CLAUDE.md still references the old world. xforge runs a staleness audit (validates paths, commands, and patterns against the live codebase) and installs a session-start hook that warns when drift is detected.

**Complex domain, too much to fit** — Medical, finance, legal projects need 300+ lines of instruction but a single bloated file gets ignored. xforge builds a multi-layer architecture: lean root file + path-scoped rules (load only when relevant) + skills (load on demand) + hooks (deterministic enforcement). Total instruction surface can be 500+ lines without diluting the core rules.

## Install

### One-liner (pinned to a release)

```bash
# Pin to a specific version for reproducibility
XFORGE_REF="v2.0.0" bash <(curl -fsSL \
  "https://raw.githubusercontent.com/cryptoxinu/xforge/v2.0.0/install.sh")
```

### With checksum verification

```bash
XFORGE_REF="v2.0.0" \
XFORGE_SHA256="<expected-sha256>" \
bash <(curl -fsSL \
  "https://raw.githubusercontent.com/cryptoxinu/xforge/v2.0.0/install.sh")
```

### Manual

```bash
git clone https://github.com/cryptoxinu/xforge.git
cd xforge
git checkout v2.0.0
./install.sh
```

Installs to `~/.claude/skills/xforge/SKILL.md`. Run `/xforge score` in any Claude Code session to see where you stand.

### What the installer does

1. Downloads `SKILL.md` from the pinned GitHub ref (not `main` unless you choose to)
2. Verifies SHA-256 checksum if `XFORGE_SHA256` is set
3. Writes to `~/.claude/skills/xforge/SKILL.md` via atomic temp file + move
4. That's it. One file. No dependencies. No runtime. No network access after install.

The installer warns if you install from a mutable branch like `main`. Pin to a tag.

## Security

**This is a Claude Code skill, not a prompt injection attack.**

xforge is a single markdown file (`SKILL.md`) that teaches Claude how to generate and maintain CLAUDE.md instruction files. The directives inside (`MUST`, `NEVER`, `IMPORTANT`, `FORBIDDEN`) are the [standard way to write effective CLAUDE.md files](https://code.claude.com/docs/en/best-practices) per Anthropic's official documentation.

What xforge does NOT do:
- No code execution at runtime (it's a markdown file with instructions)
- No network access (the installer downloads once, then it's local)
- No hidden instructions (read the full SKILL.md — it's plain text)
- No data exfiltration, no phone-home, no telemetry
- No system file modification (it writes to `.claude/` project directories only)

What the installer does:
- Downloads one file from GitHub over HTTPS
- Optionally verifies SHA-256 checksum
- Writes to `~/.claude/skills/xforge/` and nothing else
- Uses `set -euo pipefail` with atomic file operations

The generated `.claude/settings.json` includes permission deny rules that **restrict** Claude's access — blocking reads to `.env`, credentials, secrets, and writes outside the project directory. xforge makes your setup more locked down, not less.

If a security scanner flags the SKILL.md content: the directives are inside markdown code blocks as CLAUDE.md templates. They are instructions FOR Claude, not injections INTO Claude. This is the intended use of the [Claude Code skills system](https://code.claude.com/docs/en/skills).

## How it relates to /init

`/init` generates a starter CLAUDE.md. xforge is the hardening pass:

```
/init          →  basic CLAUDE.md with project info
/xforge score  →  how good is it? what's missing? what's in the wrong place?
/xforge        →  fix it — lean root + scoped rules + hooks + settings
```

They complement each other. Use both.

## Based on

All guidance in xforge is sourced from Anthropic's official documentation:

- [Best Practices](https://code.claude.com/docs/en/best-practices) — CLAUDE.md structure, verification, planning
- [Memory](https://code.claude.com/docs/en/memory) — file locations, `@import` depth limits, CLAUDE.local.md
- [Hooks](https://code.claude.com/docs/en/hooks) — event types, handler types, deterministic enforcement
- [Settings](https://code.claude.com/docs/en/settings) — permissions, sandbox, scope precedence
- [Skills](https://code.claude.com/docs/en/skills) — SKILL.md format, frontmatter, dynamic context
- [Sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing) — filesystem + network isolation

Where xforge adds opinionated rules (anti-slop, wiring verification, phased execution), they are clearly labeled as battle-tested patterns from production use, not official Anthropic guidance.

## License

[MIT](LICENSE)

## Author

[@cryptoxinu](https://github.com/cryptoxinu)
