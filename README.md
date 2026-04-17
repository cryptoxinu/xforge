# xforge

**Xinu's ClaudeMD Fix — forge battle-tested CLAUDE.md files that actually get followed.**

Stop fighting your AI assistant. `xforge` audits, scores, and generates CLAUDE.md files grounded in the official Claude Code docs (skills, memory, hooks, settings, checkpointing), HumanLayer's production research, and battle-tested community anti-slop rules from Boris Cherny, Thariq, Dex Horthy, Cat Wu, and others.

## What's new in v3

v3 merges two lineages:
- **v2.1.0's features** — staleness detection, 10-criteria scoring, SessionStart drift hook, placement framework (ROOT/RULE/SKILL/HOOK/LOCAL/PRUNE), install.sh ref-pinning
- **v2 restructure** — multi-file progressive-disclosure skill folder per the official skills spec ("Keep SKILL.md under 500 lines"), docs-verified hook syntax, per-stack templates, clarifying-questions gate for domain-critical projects

You get the deeper auditing of v2.1.0 in a maintainable folder structure that respects the 500-line SKILL.md cap.

## Structure

```
xforge/
├── SKILL.md                           # ~160-line orchestrator
├── references/
│   ├── grading-rubric.md              # 10 criteria / 100 pts (Freshness + Layer Architecture)
│   ├── staleness-audit.md             # 5-step freshness check (paths, commands, patterns, age, config drift)
│   ├── placement-framework.md         # ROOT / RULE / SKILL / HOOK / LOCAL / PRUNE classification
│   ├── line-classification.md         # PROTECTED / MOVABLE / CONSOLIDATABLE / PRUNABLE tiers
│   ├── anti-patterns.md
│   ├── template-core.md               # 8 mandatory sections + compaction safety
│   ├── templates/                     # python, typescript, go, rust, domain-critical overlay
│   ├── hooks-recipes.md               # verified hook syntax + SessionStart staleness hook
│   ├── migration-playbook.md          # large CLAUDE.md → .claude/rules/ with paths: scoping
│   ├── important-if-pattern.md        # HumanLayer conditional-rule pattern (community)
│   ├── acid-tests.md                  # Dex's "run tests first try" + partial-migration detector
│   └── gotchas.md                     # xforge's own failure log, grows with use
├── scripts/
│   ├── detect-stack.sh                # dynamic stack detection via !` injection
│   └── diff-preview.sh
├── examples/
│   ├── grade-b-targeted-fix.md
│   └── grade-d-full-regen.md
└── commands/
    ├── xforge-score.md                # /xforge score (read-only)
    └── xforge-new.md                  # /xforge new (from scratch)
```

Main `/xforge` is the skill itself — dispatches modes based on `$ARGUMENTS`.

## Commands

| Command | Changes files? | What it does |
|---|---|---|
| `/xforge score` | No | Read-only — staleness report, grade (A–F on /100), 10-criteria breakdown, line-by-line tier+placement classification, placement recommendations, acid tests |
| `/xforge` | Yes (diff-gated) | Full pipeline — discover, staleness audit, 10-criteria score, classify, grade-based improve/generate, Do-No-Harm safety check, present diff |
| `/xforge new` | Yes (diff-gated) | Generate fresh CLAUDE.md from scratch with correct stack template. For domain-critical projects, asks 4 clarifying questions first |

When run outside a git repo or when no project CLAUDE.md exists, xforge targets `~/.claude/CLAUDE.md` instead.

## What v3 does that v2 / v2.1.0 didn't, combined

**From the restructure (new to v3):**
- Progressive-disclosure skill folder — SKILL.md stays under 500 lines per official spec; deep knowledge lives in `references/` and loads on demand
- Per-stack template overlays: python, typescript, go, rust, domain-critical
- Per-mode entry points via `commands/xforge-score.md` and `commands/xforge-new.md`
- Docs-verified hook syntax throughout (matcher-as-string + `if` field, not the old tool_name/file_glob form)
- `<important if="…">` HumanLayer pattern (clearly flagged as community, not official)
- Dynamic stack detection via `!${CLAUDE_SKILL_DIR}/scripts/detect-stack.sh` injection

**From v2.1.0 (preserved in v3):**
- **Staleness audit** — path/command/pattern validation against the live codebase + git age + config drift
- **10-criteria scoring** (100 max) — adds Freshness + Layer Architecture to the original 8
- **Placement framework** — every rule routed to ROOT / RULE / SKILL / HOOK / LOCAL / PRUNE
- **Clarifying questions** for medical / financial / legal / security-critical projects
- **SessionStart staleness hook** — warns when CLAUDE.md is drifting from the codebase, zero AI cost
- **Compaction safety** instructions in generated CLAUDE.md
- **install.sh hardening** — `set -euo pipefail`, `XFORGE_REF` pinning to tags/commits, mutable-ref warnings, atomic install

## Safety guarantees

- **Do No Harm** — reads before/after, confirms every removal, presents a diff, keeps rules if unsure
- **NEVER-PRUNE classification** — PROTECTED rules (security, compliance, PHI/PII, data governance) can never be removed
- **Grade-based routing** — A/B → scalpel, C → rewrite-with-preservation, D/F → regen-with-knowledge-mining
- **Staleness audit runs first** — quality scoring can't hide a file that's referencing dead paths
- **Checkpointing awareness** — Claude Code auto-checkpoints Claude-edited files (Esc+Esc to rewind); xforge takes manual tar backups for bulk migrations only

## The 8 mandatory sections (generated CLAUDE.md)

1. **Anti-Slop Preamble** — overrides Claude's "simplest approach" default
2. **Verification Commands** — stack-specific, copy-paste-ready, FORBIDDEN to skip (Dex's "run the tests first try" test)
3. **Plan Enforcement** — separate plan from build, phased execution, 2-attempt escalation
4. **Code Quality** — root causes not symptoms, re-read before edit, soft size guidelines, no premature simplification
5. **Testing** — TDD, never weaken tests, strong assertions
6. **Project Boundary + Git Safety** — no cross-project edits, no accidental pushes
7. **Wiring Verification** — 9-item checklist proving features are wired end-to-end
   **Plus 7b — Compaction Safety** — re-ground after `/compact`
8. **Self-Improvement** — corrections compound into better rules

## Install

### One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/cryptoxinu/xforge/main/install.sh | bash
```

### Pin a version (reproducible)

```bash
XFORGE_REF=v3.0.0 bash <(curl -fsSL https://raw.githubusercontent.com/cryptoxinu/xforge/main/install.sh)
```

or pin to a commit SHA:

```bash
XFORGE_REF=82f9c0a bash <(curl -fsSL https://raw.githubusercontent.com/cryptoxinu/xforge/main/install.sh)
```

### Manual

```bash
git clone https://github.com/cryptoxinu/xforge.git
cd xforge && ./install.sh
```

All methods install skill to `~/.claude/skills/xforge/` and commands (`xforge-score`, `xforge-new`) to `~/.claude/commands/`. Existing installs are backed up with a timestamp.

After install, run `/xforge score` in any Claude Code session to see where you stand.

## Drift prevention — install the SessionStart hook

After installing xforge, also install the staleness-prevention hook (recipe 7 in `references/hooks-recipes.md`). It fires at session start, checks commit distance + config file changes since CLAUDE.md was last touched, and warns you before Claude starts working off a stale file. Pure git + bash — zero token cost.

## Size targets (sourced)

- **Under 200 lines per CLAUDE.md** — official ([code.claude.com/docs/en/memory](https://code.claude.com/docs/en/memory))
- **Under 60 lines in production** — HumanLayer's verified benchmark ([humanlayer.dev/blog/writing-a-good-claude-md](https://www.humanlayer.dev/blog/writing-a-good-claude-md))
- **Under 500 lines per SKILL.md** — official skills cap ([code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills))

Default target for generated root CLAUDE.md: ≤100 lines for non-domain-critical, up to 200 for domain-critical. Overflow goes to `.claude/rules/` with `paths:` scoping (loads on-demand when Claude touches matching files), or to `.claude/skills/` for heavy procedural content.

## Research sources

- [Claude Code docs](https://code.claude.com/docs/en) — skills, memory, hooks, settings, checkpointing (verified 2026-04)
- [HumanLayer — writing-a-good-claude-md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [HumanLayer — stop-claude-from-ignoring-your-claude-md](https://www.hlyr.dev/blog/stop-claude-from-ignoring-your-claude-md)
- [Boris Cherny's tips](https://howborisusesclaudecode.com/)
- [Thariq — how we use skills](https://x.com/trq212/status/2033949937936085378)
- [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice) — aggregated community patterns

## Security

This is a legitimate Claude Code skill, not prompt injection. It ships:
- Verified hook syntax against the official hooks docs
- install.sh with `set -euo pipefail`, atomic installs, and `XFORGE_REF` pinning to tags or commits
- Backup of existing installs with timestamps
- No network calls at runtime (only at install time, for git clone)
- No destructive operations without diff-gate + user approval

## License

MIT

## Author

[@cryptoxinu](https://github.com/cryptoxinu)
