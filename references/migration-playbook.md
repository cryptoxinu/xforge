# Migration Playbook — Large CLAUDE.md → `.claude/rules/`

For projects with CLAUDE.md files over 100 lines, especially domain-critical ones that legitimately hold a lot of rules. The goal: relocate without loss, with `paths:` scoping so rules load only when relevant.

## When to migrate

- CLAUDE.md is over 100 lines
- Certain sections are relevant to only part of the codebase (e.g. PDF pipeline rules only matter when touching `src/pdf/`)
- Rules are duplicated across sections or with rules-of-thumb in subdirectory CLAUDE.md files
- Claude's compliance is degrading ("it used to follow this rule")

## When NOT to migrate

- File is under 80 lines and working well (grade A/B)
- Rules are uniformly cross-cutting and all need to fire every session
- You haven't first tried the displacement audit (`settings-displacement.md`) — some of those lines shouldn't exist in ANY form

## Full migration sequence (safe)

### Step 0 — Bulk backup (Claude can't checkpoint tar archives)

Checkpointing handles individual file edits, but bulk `.claude/rules/` migrations involve many files. Take a tar snapshot first:

```bash
TS=$(date +%Y%m%d-%H%M%S)
tar czf ".claude/migration-backup-$TS.tar.gz" CLAUDE.md .claude/CLAUDE.md .claude/rules/ 2>/dev/null
echo "Rollback with: tar xzf .claude/migration-backup-$TS.tar.gz"
```

### Step 1 — Classify every line

Per `line-classification.md`, label every line PROTECTED / MOVABLE / CONSOLIDATABLE / PRUNABLE. Output a table. This is the foundation of the migration plan — every line in the original must map to an outcome.

### Step 2 — Audit for settings displacement

Per `settings-displacement.md`, identify rules that belong in `settings.json`, hooks, or linter config. Flag these — they leave prose entirely, not just relocate.

### Step 3 — Keep in root CLAUDE.md

Only these stay in the root:
- PROTECTED rules that are cross-cutting (apply to any file)
- Anti-slop preamble
- Verification commands (actual copy-pasteable)
- Planning rules
- High-level architecture (data flow, tier boundaries)
- Self-improvement protocol
- Reference list pointing to `.claude/rules/`

### Step 4 — Relocate MOVABLE rules

Create one file per domain. Use `paths:` frontmatter with glob patterns for on-demand loading. Verified format (code.claude.com/docs/en/memory):

```markdown
# .claude/rules/security.md
---
paths:
  - "src/security/**"
  - "src/ingest/**"
  - "src/llm/**"
---

## Security Invariants (relocated verbatim from CLAUDE.md)
- <rule 1>
- <rule 2>
...
```

```markdown
# .claude/rules/pdf-pipeline.md
---
paths:
  - "src/pdf/**"
  - "src/redaction/**"
---

<all pdf-related rules verbatim>
```

```markdown
# .claude/rules/data-governance.md
---
paths:
  - "src/data/**"
  - "src/db/**"
  - "src/reasoning/**"
---

<all data rules verbatim>
```

### Step 5 — Rules WITHOUT `paths:` load every session

For truly cross-cutting rules that must load always but deserve their own file (e.g. security invariants, compliance anchors), put them in `.claude/rules/` with NO `paths:` field. They load at root-CLAUDE.md priority every session.

```markdown
# .claude/rules/compliance.md
<no paths field — loads every session>

## HIPAA Anchors
- ...

## SOC 2 Anchors
- ...
```

Use sparingly. Rules without `paths:` compete for attention with the root file.

### Step 6 — Point root CLAUDE.md at the relocated files

```markdown
## References (in root CLAUDE.md)
- For PDF pipeline rules: see `.claude/rules/pdf-pipeline.md` (loads when working in `src/pdf/` or `src/redaction/`)
- For scheduler/task rules: see `.claude/rules/scheduler.md`
- For LLM model routing: see `.claude/rules/llm-routing.md`
- For compliance anchors: see `.claude/rules/compliance.md` (loads every session)
- For detailed architecture: see `docs/ARCHITECTURE.md`
```

Use IMPORTANT keyword when you want Claude to proactively read the linked docs: "IMPORTANT: Before starting any task, identify which rules above are relevant and read them first."

### Step 7 — Verify nothing was lost

Diff the original file against the sum of all new files. Every original line (after pruning what the user approved) must exist somewhere in the proposal.

```bash
# Rough check
wc -l CLAUDE.md .claude/rules/*.md
# Line-content check (adjusted for reformatting)
cat .claude/rules/*.md | grep -c "^- " # count bullet rules
```

Do an explicit diff review with the user before writing:

```
### Migration Diff

Original CLAUDE.md: 247 lines, 82 rules
Proposed CLAUDE.md: 68 lines, 24 rules (cross-cutting only)
Proposed .claude/rules/:
- security.md        (paths: src/security, src/ingest) — 31 rules
- pdf-pipeline.md    (paths: src/pdf, src/redaction)   — 18 rules
- scheduler.md       (paths: src/tasks)                — 9 rules

Total: 82 rules across all files (0 lost)
Displaced to settings.json/hooks: 9 rules (from settings-displacement.md)
Pruned (approved by user): 12 rules (generic/linter-territory)
```

### Step 8 — Enable InstructionsLoaded hook for verification

Right after migration, optionally wire up the InstructionsLoaded hook (see `hooks-recipes.md` recipe 6) so the user can confirm the right files load when working in relevant directories. Verify the first session after migration picks up the scoped rules as expected.

## Common pitfalls

- **Missing `paths:` when you meant to scope** — file loads every session, competing for attention. Always double-check.
- **Glob pattern typos** — `"src/pdf/**"` matches; `"src/pdf*"` matches only siblings of `pdf`. Use `**` for recursive.
- **Overly broad `paths`** — `"**/*"` defeats the purpose. Scope to actual affected directories.
- **Forgetting symlinks** — `.claude/rules/` supports symlinks, useful for sharing across projects. Resolve to check target exists.
- **Losing the "why"** — if a PROTECTED rule has historical context ("this killed us in Q3 2024"), preserve that in the relocated file. Future readers need to understand the stakes.

## Rollback plan

If the migration degrades Claude's behavior:

1. Restore from the tar snapshot: `tar xzf .claude/migration-backup-<TS>.tar.gz`
2. Run `/xforge score` on the restored file to confirm it's back
3. Document in `gotchas.md` what went wrong so xforge learns
