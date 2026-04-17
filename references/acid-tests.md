# Acid Tests

Concrete, binary tests to run against a CLAUDE.md during audit. Each returns yes/no with evidence — no hand-waving.

## Test 1: The "run the tests" test (Dex / HumanLayer)

**"Can a new dev launch Claude, say 'run the tests', and it works on the first try?"**

If no, CLAUDE.md is missing essential setup/build/test commands. This is the single highest-signal smoke test for whether CLAUDE.md earns its attention budget.

Check procedure:
1. Read CLAUDE.md for explicit commands (test, build, lint, dev-server)
2. Can Claude infer the right command from `package.json` scripts, `Makefile`, `pyproject.toml`? Sometimes, but not reliably — and not for non-standard project layouts (monorepos, custom test runners, docker-dev-envs)
3. If CLAUDE.md lacks the explicit command AND the project isn't standard-shape, you FAIL this test. Concrete gap.

Fix: add a "## Verification" section with copy-paste-ready commands. Verify by reading the ACTUAL scripts from package.json / Makefile. Never invent commands.

## Test 2: The 5-session test

**"If the user runs Claude on this project 5 times in a row, for each CLAUDE.md line, will Claude do the right thing?"**

For each line:
- **Yes, always** → this line is unnecessary (Claude does it without the rule). Candidate for PRUNE.
- **Yes, but only because of this line** → LOAD-BEARING. Keep.
- **Sometimes, and the rule is why** → LOAD-BEARING. Keep.
- **No — the rule doesn't prevent the mistake** → the rule is broken. Fix or remove.

Run mentally for each line during the score-mode classification.

## Test 3: The "10-message decay" test

**"Will Claude still follow this rule after 10+ conversation turns, when context pressure is high?"**

Rules at the TOP and BOTTOM of CLAUDE.md survive context pressure best (primacy and recency). Rules in the middle are most-violated after 10+ turns.

Audit the highest-violation rules and confirm they're at position 1-5 or position -5 to -1 of the file.

## Test 4: The displacement test

**"Could this rule be enforced by the harness (settings.json), a hook, or a linter?"**

If yes, the rule is in the wrong file. See `settings-displacement.md` for the catalog. Flag every such line.

## Test 5: The vague-verb scan

**"Does this line use a vague verb (properly, cleanly, correctly, carefully, appropriate, good)?"**

If yes, the line is not verifiable. Rewrite with concrete anchors (file paths, tool names, specific thresholds) or remove.

Example rewrites:
- "Handle errors properly" → "All async boundaries wrap in try/catch and propagate typed errors from `src/errors/`"
- "Write clean code" → cut entirely, Claude does this
- "Test thoroughly" → "Every new public function gets a unit test with at least 2 edge cases and 1 failure case"

## Test 6: The partial-migration detector

**"Does the codebase have multiple competing patterns that Claude will get confused between?"**

Scan for:
- **Next.js** — `src/pages/` AND `src/app/` both present
- **React** — class components AND functional components in new code (old files OK, new ones no)
- **Python** — `setup.py` AND `pyproject.toml` both declaring package metadata
- **TypeScript** — CommonJS AND ESM modules in the same package
- **Rust** — 2018 edition crates in a 2021 workspace
- **Go** — vendored AND module-cached deps
- **Database** — multiple ORMs (TypeORM + Prisma + raw SQL)
- **Testing** — Jest AND Vitest coexisting

For each partial migration found:
1. Flag in score output under "Partial-Migration Flags"
2. Document the TARGET pattern in CLAUDE.md ("We are migrating from X to Y. New code uses Y. Do not add to X.")
3. Propose a `.claude/rules/migration-<topic>.md` with `paths:` scoping over the legacy area

## Test 7: The positive-framing check

**"For every 'don't X' rule, is there a paired 'do Y instead'?"**

Pure negations leave Claude guessing the positive behavior. Audit all `NEVER`, `DON'T`, `AVOID` rules and pair them.

Bad: `NEVER use raw SQL in route handlers.`
Good: `NEVER use raw SQL in route handlers. Route data access through `src/repos/`. Raw SQL belongs in `src/repos/<entity>.sql` only.`

## Test 8: The "first five lines" test

**"Do the first 5 lines of CLAUDE.md contain the anti-slop preamble, or do they waste attention on project metadata?"**

First 5 lines get highest attention. They should frame Claude's default behavior override, not re-state the project name (Claude can read that from the directory).

Fix: move any "# ProjectName\n\nThis project is a tool that..." content down. Open with the anti-slop preamble.

## Test 9: The "last five lines" test

**"Do the last 5 lines contain the self-improvement protocol?"**

Recency attention means the last N lines get read heavily before each response. Use them for the rule that matters most: "after corrections, update CLAUDE.md." This creates the compounding-improvement loop.

## Test 10: The deterministic-drift test

**"Does the project have `settings.json` attribution/permissions/hooks that contradict CLAUDE.md prose?"**

Example: CLAUDE.md says `NEVER add Co-Authored-By` but settings.json doesn't set `attribution.commit: ""`. Contradiction. The prose rule loses — eventually Claude will add attribution because prose is advisory.

Audit both files. When they contradict, default to settings.json winning (it's deterministic) and update CLAUDE.md to match or remove the advisory.

## Running the tests

In score mode, output a compact checklist:

```
### Acid Tests
- [✗] Run-the-tests: no test command documented (add `npm test` from package.json)
- [✓] 5-session (per line): 24/38 lines pass. 14 flagged PRUNABLE.
- [✓] 10-message decay: highest-violation rules in positions 1-5 and -3 to -1
- [✗] Displacement: 6 lines belong in settings.json / hooks (see candidates below)
- [✗] Vague verbs: 8 occurrences found (lines 12, 34, 45, 67, 89, 102, 115, 121)
- [✗] Partial migration: Pages + App router coexist in src/
- [✗] Positive framing: 11/14 "don't" rules missing paired "do instead"
- [✓] First-5-lines: anti-slop preamble present
- [✗] Last-5-lines: ends with project trivia, self-improvement protocol missing
- [✗] Deterministic drift: CLAUDE.md "no Co-Authored-By" but settings.json doesn't enforce
```

Any `[✗]` is a concrete fix for the forge phase.
