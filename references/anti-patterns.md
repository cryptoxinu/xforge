# Anti-Patterns

Things to flag for removal or rewrite when auditing an existing CLAUDE.md.

## Wasted attention budget

- **Personality instructions** ("Act as a senior engineer", "Be helpful") — Claude already has strong system directives. This wastes attention.
- **Generic platitudes** ("Write clean code", "Use meaningful names", "Comment where helpful") — Claude does this without the rule. Zero signal.
- **Role-play framing** ("You are a world-class...") — doesn't improve output, eats instruction budget.

## Wrong file for the rule

- **Formatting rules** (indent size, quote style, line length) → move to `.editorconfig`, `.prettierrc`, `ruff.toml`, `gofmt`. Tool config is deterministic; prose is advisory.
- **Attribution / commit-message rules** → `settings.json` `attribution.commit: ""` disables Co-Authored-By deterministically. Putting "NEVER add Co-Authored-By" in CLAUDE.md is 80% reliable at best; the setting is 100%.
- **Permission boundaries** (can edit X, can't run Y) → `settings.json` `permissions.allow/deny/ask` — harness-enforced, not advisory.
- **Auto-format-on-save rules** → PostToolUse hook on Write — runs every time, not when Claude remembers.

See `settings-displacement.md` for the full audit pattern.

## Redundancy with code

- **File-by-file descriptions** of the codebase — Claude can `ls`, `glob`, and `read`.
- **Directory listings** — same. Let Claude discover.
- **Code snippets as rules** — they go stale. Use `see src/path/file.ts:123` references.
- **Detailed API documentation** — link to the actual docs: "For auth flows, see docs/auth.md".

## Fragile pointers

- **Stale references** — commands, paths, or functions that no longer exist. Before flagging, VERIFY the thing doesn't exist (grep, glob). Don't guess.
- **`@docs/huge-file.md`** embeds — `@import` pulls the entire file into every session. If it's 500 lines, every session now loads 500 extra lines. Prefer `"For X, see docs/Y.md"` reference, which costs ~1 line.

## Vague verbs

Flag any occurrence of these as VAGUE — they need rewriting with concrete anchors:

- "properly", "cleanly", "correctly", "carefully"
- "always be mindful", "keep in mind", "remember to"
- "appropriate", "reasonable", "good"
- "follow best practices" (which ones? cite)
- "avoid X when possible" (when is it not possible? specify)

A VAGUE line is a failed rule. Either rewrite with concrete paths/commands/thresholds, or remove.

## Structural anti-patterns

- **Multiple rules saying the same thing** — consolidate per `line-classification.md`.
- **"Don't X" with no "do Y instead"** — pure negations leave Claude guessing the positive behavior.
- **Rules ordered randomly** — primacy and recency matter. The first 5 lines and last 5 lines get disproportionate attention. Put the highest-violation rules there.
- **Overly long paragraphs** — Claude skims structure the same way readers do. Use headers + bullets.
- **Contradicting rules across sections** — "always X" in section 2, "never X" in section 7. Find them, resolve them.

## Over-budget file

- **Over 200 lines** — official docs flag this as reducing adherence.
- **Over 60 lines** — HumanLayer's production benchmark. If you're above this, strongly consider migrating chunks to `.claude/rules/` with `paths:` scoping (loads on demand, doesn't compete for root attention).
- **Multiple `@imports`** of large files — each expands inline at session start. Count the effective lines, not just the CLAUDE.md line count.

## Self-defeating rules

- **"NEVER delete files without asking"** — good, but if every session you also need to delete generated build artifacts, the rule is violated routinely and Claude learns to ignore it. Scope it: "NEVER delete source files without asking. `dist/`, `build/`, `.cache/` are safe to clean."
- **"ALWAYS run the full test suite before commit"** — if the suite takes 40 minutes, this rule dies on contact with reality. Specify a subset: "Run `pytest tests/unit -q` before commit. Full suite runs in CI."
- **Rules that require tools/commands that aren't installed** — verify the command exists before generating the rule.

## Removal checklist

Before pruning, confirm for every line:
1. It's in PRUNABLE, not PROTECTED
2. Nothing in the codebase relies on Claude knowing this
3. The user hasn't corrected Claude on this in the last N sessions (if you can tell)
4. Removing it passes the "5-session test" — will Claude do the right thing 5 sessions from now without this line?

If any doubt, keep the line. Bloat is recoverable; destroyed rules are not.
