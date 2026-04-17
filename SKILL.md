---
name: xforge
description: "Xinu's ClaudeMD Fix — audit, score, improve, and generate battle-tested CLAUDE.md files that actually get followed. Uses verified Claude Code skill/memory/hooks docs, HumanLayer research, and community best practices."
when_to_use: "Use when the user asks to improve, fix, audit, score, or generate a CLAUDE.md file. Triggers on phrases like: 'improve my claude md', 'fix my claude.md', 'my CLAUDE.md sucks', 'claude keeps ignoring rules', 'score my claude.md', 'rate my CLAUDE.md', '/xforge', '/xforge score', '/xforge new'. Also use proactively when reviewing a repo's CLAUDE.md if the user signals dissatisfaction with rule adherence."
argument-hint: "[score|new|<path>]"
allowed-tools: Read Grep Glob Bash Write Edit
---

# Xforge — ClaudeMD Forge

Audit and forge CLAUDE.md files that actually get followed. Grounded in verified Anthropic docs (cap: 200 lines official, gold standard ~60 per HumanLayer), the Claude Code skills/hooks/settings reference, and community best practices from Boris Cherny, Thariq, Dex, and davila7.

## Dispatch (based on $ARGUMENTS)

- **`$ARGUMENTS` = "score"** → READ-ONLY audit. Run: Discover → Audit → Classify. Output the score report. NEVER write, edit, or back up. Skip safety phase entirely.
- **`$ARGUMENTS` = "new"** → Generate fresh CLAUDE.md. Run: Backup → Discover → Generate → Safety check → Present diff.
- **`$ARGUMENTS` empty OR a path** → Full pipeline. Run: Backup → Discover → Audit → Classify → Decide (grade-based) → Generate/improve → Safety check → Present diff.

If run outside a git repo OR no project CLAUDE.md exists, target `~/.claude/CLAUDE.md` (user's personal defaults) instead. Announce which file you are targeting before starting.

## Dynamic Stack Context

```!
${CLAUDE_SKILL_DIR}/scripts/detect-stack.sh
```

Use that output to pick the right template overlay from `references/templates/`. If the script is unavailable, fall back to reading `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, or similar yourself.

## Pipeline

### 1. Discover (always)

Read the existing `CLAUDE.md` (project, `.claude/CLAUDE.md`, or `~/.claude/CLAUDE.md`). List `.claude/rules/*.md`. Scan `package.json` scripts, `Makefile` targets, `pyproject.toml` tool configs for actual build/test/lint commands. Note: test framework, lint config, build tooling, key architectural patterns, domain type (generic / medical / finance / security / legal).

Detect partial framework migrations (mixed Pages+App router, CommonJS+ESM, class+functional React, setup.py+pyproject.toml). Flag them — they confuse Claude.

**Domain-critical gate**: if the project handles PHI / PCI / auth-critical / legal / safety-critical, AND 3+ of (custom build pipeline, domain-specific data handling, multiple deployment targets, compliance requirements, encryption/vault code, audit-log tables) are present, ASK the four clarifying questions from `references/templates/domain-critical.md` BEFORE generating anything.

### 2. Staleness audit (always — run BEFORE quality scoring)

Use tools, not assumptions. Per `references/staleness-audit.md`, run:

1. **Path validation** — Glob/ls every project-specific path in CLAUDE.md
2. **Command validation** — `command -v` every referenced binary; safe dry-run where possible
3. **Pattern validation** — Grep every named function/class/module
4. **Age check** — `git log` to compute commits and days since CLAUDE.md was last touched
5. **Config drift** — compare package.json / Makefile / pyproject.toml against CLAUDE.md's documented commands

Staleness findings appear in the score report BEFORE the 10-criteria breakdown. A file can score well on quality but still be dangerously stale.

### 3. Audit (if existing file present)

Score against **10 criteria** (0–10 each, 100 max) from `references/grading-rubric.md`. Grade scale:

| Grade | Score | Action |
|---|---|---|
| A | 80–100 | DO NOT REWRITE. Add missing sections only. Tighten vague lines. Short diff. |
| B | 60–79 | TARGETED IMPROVEMENTS. Add missing mandatory sections, sharpen vague rules. No removals. |
| C | 40–59 | REWRITE with full rule preservation (see `references/line-classification.md`). |
| D | 20–39 | REBUILD. Scan old for project-specific knowledge, fold into fresh generation. |
| F | 0–19 | NUKE. Full regeneration. |

Grade can drop from staleness findings (see rubric for exact penalties).

### 4. Classify every line — tier AND placement

For each line, output BOTH classifications:
- **Tier** (per `references/line-classification.md`): PROTECTED / MOVABLE / CONSOLIDATABLE / PRUNABLE
- **Placement** (per `references/placement-framework.md`): ROOT / RULE / SKILL / HOOK / LOCAL / PRUNE

The tier says "what it is"; the placement says "where it goes". Dual classification makes the fix obvious.

Any rule flagged for HOOK / settings.json is **deterministic once moved** — prose is ~80% reliable, hooks are 100%. Every displacement is a free compliance win.

### 5. Decide based on grade (non-`score` modes)

Grade A/B: targeted edit only. Grade C: rewrite while preserving every PROTECTED + MOVABLE line. Grade D/F: full regen using `references/template-core.md` + the relevant stack template.

For `$ARGUMENTS` = "new", skip Audit and Classify — go straight to generation from `references/template-core.md`. Apply the domain-critical clarifying questions gate if applicable.

### 6. Safety check (Do No Harm — BEFORE any write)

Before writing anything (skip this entirely for `score` mode):

1. Read original and proposed side-by-side
2. For every REMOVED line — confirm it's dead weight, not hard-won project rule. If unsure, KEEP IT
3. For every CHANGED line — confirm the new version is strictly more specific, not vaguer. "Always validate inputs" → "All API endpoints MUST validate with Zod" = good. Reverse = destructive
4. For every ADDED line — confirm load-bearing: does Claude actually need this rule to avoid a mistake?
5. Ask: "If the user runs this in their next 5 sessions, will Claude behave BETTER or WORSE?" Any doubt → present as suggestions, do not apply
6. Present a unified diff with a short WHY for each change. Never silently rewrite

Checkpointing is automatic in Claude Code — every prompt creates a restore point (Esc+Esc or `/rewind`). That covers Claude-edited files. For bulk `.claude/rules/` migrations via shell, you still want a tar backup first (see `references/migration-playbook.md`).

### 7. Present (all modes)

For `score` mode — use the exact format from `references/grading-rubric.md` (Staleness Report → 10-Criteria Breakdown → Classification → Placement Recommendations → Top 3 Issues → Acid Tests).

For `/xforge` and `/xforge new` — additionally include:

```
### Proposed Changes
[Unified diff with WHY annotations]

### Files to write
- CLAUDE.md (<N lines>)
- .claude/rules/<name>.md (if applicable)
- .claude/skills/<name>/SKILL.md (if applicable — procedural content extracted)
- .claude/hooks/*.sh + settings.json patch (if displacement audit found deterministic rules)
- CLAUDE.local.md (if personal/machine-specific rules found)

### Next Steps
1. Review the diff — every line should feel necessary
2. Say "write it" to apply
3. Install the SessionStart staleness hook from references/hooks-recipes.md to prevent drift
4. Re-run `/xforge score` after 30 days or 50 commits
5. After corrections: ask Claude to update CLAUDE.md so the mistake doesn't repeat
```

## References (progressive disclosure — load on demand)

- `references/grading-rubric.md` — **10-criteria** scoring (100 max) + score-mode output format
- `references/staleness-audit.md` — 5-step freshness check (paths, commands, patterns, age, config drift)
- `references/placement-framework.md` — ROOT / RULE / SKILL / HOOK / LOCAL / PRUNE classification
- `references/line-classification.md` — PROTECTED / MOVABLE / CONSOLIDATABLE / PRUNABLE tiers
- `references/anti-patterns.md` — what to flag and remove
- `references/template-core.md` — 8-section master template + compaction-safety clause
- `references/templates/python.md` · `typescript.md` · `go.md` · `rust.md` · `domain-critical.md`
- `references/hooks-recipes.md` — verified hook syntax + SessionStart staleness prevention hook
- `references/migration-playbook.md` — smart migration for large CLAUDE.md → `.claude/rules/`
- `references/important-if-pattern.md` — HumanLayer community conditional-rule technique (not official)
- `references/acid-tests.md` — Dex's "run tests first try" test + partial-migration detector
- `references/gotchas.md` — xforge's own failure log; append after every mistake
- `examples/grade-b-targeted-fix.md` · `examples/grade-d-full-regen.md`

Load the ones you need for the task at hand. Don't load everything.

## Size Targets (verified sources)

- **Under 200 lines per CLAUDE.md** — official recommendation (code.claude.com/docs/en/memory)
- **Under 60 lines in production** — HumanLayer's verified benchmark (`humanlayer.dev/blog/writing-a-good-claude-md`)
- **Under 500 lines per SKILL.md** — official cap for skills themselves

Default target for generated root CLAUDE.md: **≤100 lines**. Overflow goes to `.claude/rules/` with `paths:` scoping, which loads on-demand when Claude touches matching files. Domain-critical projects (medical, finance, security) can legitimately need 150+ — the point is not arbitrary cutting, it's that every line must get followed.

## Gotchas

Append here after every time xforge makes things worse. Keep entries concrete.

- (none yet — this section grows with use)

## Sources

- Claude Code skills, memory, hooks, settings, checkpointing: `code.claude.com/docs/en/*` (verified 2026-04)
- HumanLayer writing-a-good-claude-md · stop-claude-from-ignoring-your-claude-md
- Boris Cherny / Thariq / Cat Wu / Dex Horthy tip threads (aggregated at `github.com/shanraisshan/claude-code-best-practice`)
- Instruction budget theory: ETH Zurich research, Karpathy LLM-wiki pattern
