# Grading Rubric

Score a CLAUDE.md against **10 criteria** (0–10 each, 100 max). Each criterion has a concrete "what to check" test. No vibes — every score must cite a specific line number or specific absence.

v3 adds Freshness and Layer Architecture to the original 8, reflecting that (a) a technically-correct CLAUDE.md referencing dead paths is broken, and (b) a file that should be using `.claude/rules/` / `HOOK` / `SKILL` but isn't is costing compliance.

## The 10 criteria

| # | Criteria | 0–3 | 4–6 | 7–10 |
|---|---|---|---|---|
| 1 | **Conciseness** | >300 lines, drowning in boilerplate | 150–300 lines, some bloat | <100 lines, every line load-bearing |
| 2 | **Verification Commands** | None | Commands listed but not enforced | Copy-paste-ready + "FORBIDDEN to claim done until these pass" |
| 3 | **Anti-Slop Rules** | None | Generic "write clean code" | Specific rules against bandaids, truncation, premature simplification |
| 4 | **Plan Enforcement** | None | Vague mention of planning | Concrete "plan ONLY, no code until approved" + phased execution |
| 5 | **Specificity** | Full of vague verbs ("properly", "clean") | Mixed | Every rule verifiable — paths, tool names, exact commands |
| 6 | **No Redundancy** | Duplicates linter, repeats itself, lists files | Some overlap with tooling | Each rule in exactly one place, no overlap with `.editorconfig`/`prettier`/`ruff`/etc |
| 7 | **Positive Framing** | Pure negations ("don't do X") | Mixed | Every "don't X" paired with "do Y instead" |
| 8 | **Architecture Clarity** | Missing non-obvious patterns | Mentions patterns but vague | Documents data flow invariants, gotchas, domain constraints |
| 9 | **Freshness** | >90 days old, multiple dead paths/commands | Some drift, 1–2 dead refs | Validated against live codebase, no dead paths/commands |
| 10 | **Layer Architecture** | All in root, nothing in `.claude/rules/` or hooks | Some rules misplaced | Clean split: ROOT cross-cutting, RULE path-scoped, HOOK deterministic, SKILL procedural |

## Grade scale (v3 — 100-point scale)

| Grade | Total | Meaning | Action |
|---|---|---|---|
| A | 80–100 | Production-grade, ship it | DO NOT rewrite. Targeted diffs only |
| B | 60–79 | Good foundation, gaps | Add missing mandatory sections, sharpen vague rules |
| C | 40–59 | Mediocre, structural gaps | Rewrite while preserving all project-specific rules |
| D | 20–39 | Actively confusing | Rebuild. Mine old for domain knowledge |
| F | 0–19 | Sabotaging Claude | Full regeneration |

**Grade penalties from staleness findings** (see `staleness-audit.md`):
- >3 dead paths/commands → drop one letter grade
- Age >90 days + config drift → drop one letter grade
- Both → drop two letter grades and recommend full regeneration

## Criterion 9 — Freshness (detailed)

Score this using the outputs of `references/staleness-audit.md`. Every finding contributes:

| Finding | Score impact |
|---|---|
| All paths valid, all commands work | 10/10 |
| 1–2 dead paths OR 1 bad command | 7/10 |
| 3–5 dead paths OR multiple stale patterns | 4/10 |
| Age >90 days OR >50 commits behind | Cap at 5/10 regardless of other findings |
| Config drift (package.json scripts don't match documented commands) | Cap at 4/10 |
| File not tracked by git | 3/10 + warn |

Freshness is AND-gated by the staleness audit — you cannot score >7 without running the audit successfully.

## Criterion 10 — Layer Architecture (detailed)

Score by classifying every rule and checking if it's in the right layer (see `placement-framework.md`):

| Finding | Score impact |
|---|---|
| Rules cleanly split across ROOT / RULE / SKILL / HOOK / LOCAL | 10/10 |
| Minor misplacement — 1–2 rules that should be HOOK or RULE | 7/10 |
| Moderate — 5+ deterministic rules as prose, no hooks configured | 4/10 |
| Severe — root CLAUDE.md >250 lines with no `.claude/rules/` migration done | 2/10 |
| All 4 layers (RULE, SKILL, HOOK, LOCAL) empty despite project complexity warranting them | 0–2/10 |

Good signal: run `ls .claude/rules/` — if empty but the project is non-trivial, layer architecture is weak.

## Score-mode output format (exact)

When `$ARGUMENTS` = "score", output exactly this shape and change nothing:

```
## CLAUDE.md Health Check

**Project**: <name> | **Stack**: <detected> | **Lines**: <count>
**Target file**: <path> | **Score**: <X/100> — **Grade <A–F>**

### Staleness Report (run FIRST, see references/staleness-audit.md)
- Path check: <N> paths validated, <D> dead
  → <list dead paths with reason>
- Command check: <N> commands tested
  → <list results>
- Pattern check: <N> patterns grepped
  → <list results>
- Age: <N> commits, <D> days since last update → <FRESH|AGING|STALE>
- Config drift: <summary>

### 10-Criteria Breakdown
| # | Criteria | Score | Evidence (line refs) |
|---|---|---|---|
| 1 | Conciseness | X/10 | line 1–247: 247 lines, 180 over target |
| 2 | Verification Commands | X/10 | line 34 mentions `npm test` but no gate |
| 3 | Anti-Slop Rules | X/10 | none present |
| 4 | Plan Enforcement | X/10 | line 12 says "plan first" (vague) |
| 5 | Specificity | X/10 | lines 45, 67, 89 use "properly", "clean", "good" |
| 6 | No Redundancy | X/10 | lines 112–130 duplicate .eslintrc |
| 7 | Positive Framing | X/10 | 11/14 "don't" rules lack a "do instead" |
| 8 | Architecture Clarity | X/10 | no data-flow rules; pattern used in 12 files not documented |
| 9 | Freshness | X/10 | 2 dead paths, 1 bad command, age 34 days |
| 10 | Layer Architecture | X/10 | everything in root, no .claude/rules/ despite monorepo |

### Line-by-Line Classification (tier + placement)
Line 5:  "All endpoints must validate..."     → LOAD-BEARING → ROOT
Line 12: "Write clean code"                   → GENERIC → PRUNE
Line 18: "NEVER store plaintext PHI"          → PROTECTED → ROOT
Line 25: "Use the repo pattern"               → VAGUE → ROOT (rewrite with paths)
Line 30: "PDF pipeline must sanitize..."      → LOAD-BEARING → RULE (.claude/rules/pdf.md)
Line 40: "Deploy checklist: step 1..."        → LOAD-BEARING → SKILL (.claude/skills/deploy/)
Line 45: "Auto-format on save"                → ENFORCEMENT → HOOK (PostToolUse)
Line 50: "My local DB is on port 5433"        → PERSONAL → LOCAL (CLAUDE.local.md)

### Placement Recommendations
[Grouped summary of what moves where]
- Move to `.claude/rules/`: <list>
- Move to `.claude/skills/`: <list>
- Move to hooks: <list>
- Move to settings.json: <list>
- Move to CLAUDE.local.md: <list>
- Prune: <list>

### Top 3 Issues
1. <most impactful, 1 sentence>
2. <second, 1 sentence>
3. <third, 1 sentence>

### What's Working
- <1–2 things the file does well — give credit>

### Acid Tests (see references/acid-tests.md)
- [✓/✗] Run-the-tests first try
- [✓/✗] Displacement — rules in the right layer
- [✓/✗] Vague-verb scan
- [✓/✗] Partial-migration flags
- [✓/✗] First/last 5 lines carry highest-leverage rules
- [✓/✗] Deterministic drift (settings.json ↔ CLAUDE.md consistency)

### Partial-Migration Flags
<any mixed-framework states detected>

### Next Step
Run `/xforge` to auto-fix (diff-gated, safety-checked).
```

Changes NOTHING in score mode. No backups, no writes, no permission prompts.
