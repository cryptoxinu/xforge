# `<important if="...">` Pattern (community)

A conditional-rule pattern from HumanLayer (`hlyr.dev/blog/stop-claude-from-ignoring-your-claude-md`). It's **not an official Claude Code feature** — Claude doesn't parse the tags specially. But the conditional framing appears to improve rule adherence in practice, especially as files grow and Claude's tendency to skim increases.

## How it looks

```markdown
<important if="you are writing or modifying tests">
- Use `createTestApp()` helper for integration tests
- Mock the database via fixtures, never call the live DB
- Assert against specific values, not "truthy"
</important>

<important if="you are editing the PDF redaction pipeline">
- NEVER bypass the OCR pass — even for "already-clean" PDFs
- ALL writes to `redacted_out/` go through `src/pdf/writer.py`, which verifies the OCR signature
- On failure, throw — never return the unredacted file
</important>
```

## Why it appears to work

The theory (unconfirmed by Anthropic, self-reported by HumanLayer):

1. The explicit condition gives Claude a clearer activation signal — "this section is for me when I'm doing X" vs leaving the relevance decision to Claude
2. Wrapping in a distinct tag breaks the "skim past middle of file" pattern that hurts compliance as files grow
3. Human readability improves too, which reduces maintenance entropy

HumanLayer reports: "we've seen noticeably better adherence on tasks where only some sections of my CLAUDE.md should apply." **No quantitative data.** Treat as a community-validated heuristic, not a proven win.

## When to use it

- Project has clear domain boundaries (testing vs prod code, PHI handling vs generic logic)
- CLAUDE.md is approaching or past the 100-line mark and adherence is degrading
- You don't want to migrate to `.claude/rules/` with `paths:` scoping yet (that's the official mechanism for the same effect)

## When NOT to use it

- Wrapping everything — defeats the signal; now Claude has to decide for every block
- Broad conditions like `<important if="you are writing code">` — vacuous, always true
- Rules that are truly cross-cutting — no condition applies, use plain prose
- Rules that should be hard-enforced — use hooks instead (see `settings-displacement.md` and `hooks-recipes.md`)

## Preferred: official `.claude/rules/` path scoping

The official Claude Code way to achieve "only load this rule when working in X area" is `.claude/rules/` with `paths:` frontmatter (see `migration-playbook.md`). That mechanism is parsed by the harness and loads/unloads deterministically based on which files Claude is reading.

Decision tree:

- **Many rules, clear directory boundary** → use `.claude/rules/<topic>.md` with `paths:` (official, deterministic)
- **Few rules, same file OK** → use `<important if>` inline (community, advisory but signal-boosting)
- **Hard requirement, never skip** → use a hook (deterministic, 100% enforced)
- **Cross-cutting, always applies** → plain prose in root CLAUDE.md

## Format recommendations

Write conditions as the developer would phrase them ("you are", not "the assistant is"). Front-load the key action:

```markdown
<important if="you are touching auth or session code">
NEVER store session tokens in localStorage — use HTTP-only cookies via `src/auth/session.ts`.
</important>
```

Keep each block focused on ONE context. Stacking many conditions in one block dilutes the signal.

## Interaction with `paths:` rules

You can combine both — put the `<important if>` block inside a `.claude/rules/*.md` file that's also `paths:`-scoped. Double conditional: the file loads only when the path matches, AND the block's condition reinforces relevance within the file. Useful for very long rule files where different sections apply to different parts of the scoped area.

## Example: domain-critical project

```markdown
# .claude/rules/phi-handling.md
---
paths:
  - "src/patient/**"
  - "src/ehr/**"
  - "src/export/**"
---

# PHI Handling Rules

<important if="you are writing logging, telemetry, or error reporting">
NEVER log raw request bodies when they may contain PHI.
ALWAYS pass through `src/phi/scrubber.py::scrub()` before any log, print, metric, or trace.
</important>

<important if="you are writing PDF ingestion, OCR, or document parsing">
ALL PDF uploads MUST pass `redaction_pipeline.run()` before any storage write.
The pipeline is fail-closed. On OCR failure the file is REJECTED — never stored.
</important>

<important if="you are modifying the data export or audit log">
Exports produce an audit row per record. `audit.log_export(user_id, record_ids)` MUST be called in the same transaction as the export itself.
</important>
```
