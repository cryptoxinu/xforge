# Staleness Audit

A CLAUDE.md can score well on every quality criterion and still be **dangerously stale** — referencing paths that no longer exist, build commands that don't work, functions that got renamed. Run this audit during EVERY `/xforge score` and `/xforge` run, BEFORE scoring quality.

**Principle: don't read CLAUDE.md and assume it's correct.** Use tools to cross-reference every project-specific claim against the live codebase.

## The 5 staleness checks

### 1. Path validation

Extract every file/directory path from CLAUDE.md that looks project-specific: backticked paths, `@import` targets, `src/...` references, config file references, `.claude/rules/*.md` pointers.

For each:
- Use **Glob** or **Bash `ls`** to check it exists on disk
- **Skip generic examples** like `src/api/**` (illustrative) — only validate paths that reference THIS project's real directories

Flag dead paths as warnings, not errors. The user confirms before removal — a path might look dead but still be referenced by dynamic code.

### 2. Command validation

Extract shell commands from the Verification / build / test / lint sections of CLAUDE.md.

For each:
- Use **Bash `command -v <binary>`** to verify the binary exists
- For commands that are safe to dry-run (`npx tsc --noEmit`, `cargo check`, `go vet ./...`), actually run them and report the exit code
- NEVER dry-run commands with side effects (`npm run deploy`, `git push`, `make release`)

Report which commands succeed, fail, and which binaries aren't installed.

### 3. Pattern validation

If CLAUDE.md mentions specific functions, classes, modules, or environment variables by name, use **Grep** to search the codebase for each.

Flag any pattern that returns zero matches — these reference code that no longer exists. Examples:
- `"handle_upload()"` — grep → 0 results → stale reference
- `"process_legacy()"` — grep → 0 results → was renamed, never updated in CLAUDE.md
- `"DATABASE_URL"` — grep `process.env.DATABASE_URL` → 3 hits → live

### 4. Age check

Use git to check when CLAUDE.md was last touched and how far the codebase has moved since.

```bash
# Commits since CLAUDE.md was last updated
LAST_HASH=$(git log -1 --format=%H -- CLAUDE.md)
COMMITS_SINCE=$(git rev-list --count "${LAST_HASH}..HEAD")

# Days since last update
DAYS_SINCE=$(( ( $(date +%s) - $(git log -1 --format=%ct -- CLAUDE.md) ) / 86400 ))
```

Thresholds:
- **FRESH**: <25 commits, <30 days since last update
- **AGING**: 25–50 commits OR 30–90 days
- **STALE**: >50 commits OR >90 days — aggressive re-audit recommended

### 5. Config drift

Use **Read** to compare live config files against what CLAUDE.md documents:

- `package.json` `scripts` vs CLAUDE.md Verification commands
- `Makefile` targets vs CLAUDE.md commands
- `pyproject.toml` `[tool.*]` sections vs CLAUDE.md linter/test references
- `Cargo.toml` workspace structure vs documented layout
- `go.mod` module path vs documented imports

Flag mismatches. Examples:
- CLAUDE.md says `npm test`, `package.json` has `"test": "vitest run"` → document the actual command
- CLAUDE.md mentions `black`, `pyproject.toml` only has `[tool.ruff]` → remove black reference, document ruff
- CLAUDE.md imports `@docs/api.md`, file doesn't exist → remove the import

## Show your work

Every staleness check must produce a concrete line the user can audit. Do not output "CLAUDE.md is fresh" without evidence. Example output:

```
Staleness Report:
- Path check: 12 paths validated, 2 dead
  → src/old-module/ (deleted in commit abc123)
  → docs/v1-api.md (renamed to docs/api.md)
- Command check: 4 commands tested
  → `ruff check src/ tests/` ✓ (exit 0)
  → `pytest -q` ✓ (exit 0)
  → `mypy src/` ✗ (mypy not installed)
  → `npm run deploy` skipped (has side effects)
- Pattern check: 3 functions grepped
  → handle_upload() ✓ (3 hits)
  → process_legacy() ✗ (0 hits, stale)
  → validate_input() ✓ (7 hits)
- Age: 23 commits, 14 days since last update → FRESH
- Config drift: pyproject.toml scripts match CLAUDE.md ✓
```

## When staleness findings surface in the score report

Staleness findings appear in a **dedicated section BEFORE** the 10-criteria breakdown. This ordering matters — a file that scores 78/100 but has 5 dead paths is functionally broken even if the prose quality is fine.

For grade impact:
- **>3 dead paths or commands** → drop one letter grade (e.g. B → C)
- **STALE age + config drift** → drop one letter grade
- **Both** → drop two letter grades and recommend full regeneration

## Prevention: SessionStart drift hook

After fixing staleness, install the SessionStart hook from `hooks-recipes.md` → "Recipe: Staleness Prevention". The hook fires at session start, runs the same age + config-drift checks, and warns the user BEFORE they start working from a stale CLAUDE.md.

Hook is pure git + bash — no AI calls, zero token cost. Catches the 80% case (commands changed, dependencies updated) without a full audit run.
