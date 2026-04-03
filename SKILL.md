---
name: xforge
description: "Xinu's ClaudeMD Fix — audit, score, improve, and generate battle-tested CLAUDE.md files that enforce plan adherence, prevent bandaid fixes, and eliminate refactoring debt."
origin: custom
---

# Xinu's ClaudeMD Fix

Forge battle-tested CLAUDE.md files that actually get followed. Based on research from 50+ production CLAUDE.md files, Boris Cherny's team practices, ETH Zurich's instruction-budget research, and battle-tested anti-slop rules from the community.

## When to Activate

- `/xforge` — audit + improve existing CLAUDE.md in current project (always backs up first)
- `/xforge analyze` — read-only analysis: score, classify every rule, recommend improvements — changes NOTHING
- `/xforge new` — generate fresh CLAUDE.md for current project from scratch
- `/xforge audit` — score-only mode with grade (A-F), no changes
- `/xforge global` — improve `~/.claude/CLAUDE.md`
- When user says "improve my claude md", "fix my claude.md", "my claude.md sucks", "claude keeps ignoring rules"

## Phase 0: Mandatory Backup (ALWAYS — before ANY change)

Before touching ANY existing CLAUDE.md or .claude/rules/ file, ALWAYS create a timestamped backup:

```bash
# Backup root CLAUDE.md
!`cp CLAUDE.md "CLAUDE.md.backup.$(date +%Y%m%d-%H%M%S)" 2>/dev/null`
# Backup .claude/CLAUDE.md if it exists
!`cp .claude/CLAUDE.md ".claude/CLAUDE.md.backup.$(date +%Y%m%d-%H%M%S)" 2>/dev/null`
# Backup all rules files
!`tar czf ".claude/rules-backup-$(date +%Y%m%d-%H%M%S).tar.gz" .claude/rules/ 2>/dev/null`
```

Tell the user: "Backed up your existing files. If anything goes wrong, your originals are preserved with timestamps. You can always restore."

NEVER skip this step. NEVER overwrite without backup. This is non-negotiable.

## Phase 1: Project Discovery

Scan the project to understand it before writing a single rule:

```bash
# Detect language and framework
!`ls package.json Cargo.toml go.mod pyproject.toml setup.py requirements.txt Makefile Gemfile build.gradle pom.xml 2>/dev/null`

# Detect build/test/lint commands
!`cat package.json 2>/dev/null | grep -A 20 '"scripts"'`
!`cat Makefile 2>/dev/null | grep -E '^[a-zA-Z_-]+:' | head -20`
!`cat pyproject.toml 2>/dev/null | head -40`

# Detect existing CLAUDE.md and rules
!`cat CLAUDE.md 2>/dev/null; cat .claude/CLAUDE.md 2>/dev/null; ls .claude/rules/ 2>/dev/null`

# Detect project structure
!`find . -maxdepth 2 -type f \( -name "*.ts" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.swift" \) | head -30`

# Detect test framework
!`ls tests/ test/ __tests__/ spec/ *_test.go **/*.test.ts **/*.spec.ts 2>/dev/null | head -10`

# Check git setup
!`git remote -v 2>/dev/null | head -2`
!`git log --oneline -5 2>/dev/null`
```

## Phase 2: Audit Existing CLAUDE.md (if present)

Score against 8 criteria (0-10 each, 80 max):

| Criteria | What to Check |
|---|---|
| **Conciseness** | Under 80 lines? Every line passes "would Claude fail without this?" test? |
| **Verification Commands** | Has copy-paste-ready build/test/lint commands? |
| **Anti-Slop Rules** | Has rules preventing bandaids, scope drift, half-implementations? |
| **Plan Enforcement** | Has rules separating plan from build, requiring approval? |
| **Specificity** | Rules are concrete and verifiable, not vague ("write clean code")? |
| **No Redundancy** | No rules Claude can infer from code? No duplicating linter territory? |
| **Positive Framing** | Every "don't X" has a "do Y instead"? |
| **Architecture Clarity** | Non-obvious patterns, gotchas, and decisions documented? |

### Anti-Patterns to Flag

Flag and remove these if found:
- Personality instructions ("Act as a senior engineer") — wastes tokens, Claude already has strong system directives
- Generic advice ("Write clean code", "Use meaningful names") — obvious, wastes instruction budget
- `@docs/file.md` embeds — pulls entire files into every session; use "For X, see docs/Y.md" instead
- Code snippets — go stale fast; use file:line references
- Formatting rules — belong in .editorconfig/.eslintrc/.prettierrc, not CLAUDE.md
- Duplicate rules — each rule in exactly one place
- Directory listings — Claude can `ls` the project
- Stale references — commands/paths that no longer exist
- Lines over 150 total — every line added makes every other line less likely to be followed

### Quality Gate

- **A (65-80)**: Production-grade, ship it
- **B (50-64)**: Good foundation, minor improvements needed
- **C (35-49)**: Mediocre, significant gaps — rewrite recommended
- **D (20-34)**: More harm than good — delete and regenerate
- **F (0-19)**: Actively sabotaging Claude — nuke from orbit

Output the score, then list specific improvements.

## Phase 2.5: Make Every Line Load-Bearing (Improve Existing)

When improving an existing CLAUDE.md (not generating from scratch), the goal is to make every line carry maximum weight. For each line in the existing file, apply this decision tree:

**1. Is this line project-specific knowledge Claude cannot infer from code?**
   - YES → Keep. This is load-bearing.
   - NO → Candidate for removal. Test: delete it mentally. Would Claude break something?

**2. Is this line concrete and verifiable?**
   - "Always validate inputs" → TOO VAGUE. Rewrite to: "All API endpoints MUST validate input with [project's schema lib] before processing"
   - "Use the repository pattern" → TOO VAGUE. Rewrite to: "Data access goes through `src/repos/`. Never query the DB directly from route handlers"

**3. Is this line missing context Claude needs?**
   - Scan the project for: build commands, test runners, linters, key architectural patterns, known gotchas, data flow invariants
   - If the CLAUDE.md doesn't mention them but Claude would need them, ADD them
   - Example: project uses a custom build step but CLAUDE.md only says "npm test" — add the full verification chain

**4. Is this line duplicating what a linter/formatter enforces?**
   - YES → Remove from CLAUDE.md, confirm the tool config exists

**5. Does this line have a positive alternative?**
   - "Don't use X" → Rewrite to: "Don't use X — use Y instead"
   - Negative-only rules leave Claude guessing what TO do

**After this pass, every remaining line should be: specific, verifiable, project-unique, and load-bearing.**

When running `/xforge analyze`, output the classification for every line:
```
Line 12: "Always use repository pattern" → VAGUE — rewrite with specific paths
Line 15: "Run ruff check before commit" → LOAD-BEARING — keep
Line 23: "Write clean code" → GENERIC — remove (Claude already does this)
Line 31: "All PDF uploads must pass redaction pipeline" → PROTECTED — keep (domain-critical)
```

## Phase 3: Generate / Rewrite CLAUDE.md

IMPORTANT: The generated CLAUDE.md MUST be under 80 lines for simple projects. Every line must pass this test: **"Would removing this cause Claude to make a wrong decision it couldn't recover from by reading the code?"** If no, cut it.

### Mandatory Sections (in this order — primacy matters)

The CLAUDE.md you generate MUST include ALL of these sections, adapted to the project's stack. The rules below are the distilled best-of from 50+ production files — do NOT water them down or make them generic.

---

#### Section 1: Anti-Slop Preamble (FIRST 5 LINES — highest attention)

```markdown
# [Project Name]

IMPORTANT: Override your defaults to "avoid improvements beyond what was asked" and "try the simplest approach." Those produce bandaids. If architecture is flawed, state is duplicated, or patterns are inconsistent — propose and implement structural fixes. Find root causes, not symptoms. No temporary fixes. No workarounds. No "simplified versions."

YOU MUST separate planning from building. When asked to plan: output ONLY the plan with unresolved questions. No code until the user approves. When given a plan: follow it exactly. If you spot a problem, flag it and WAIT — do not improvise or reduce scope.
```

#### Section 2: Verification Commands

```markdown
## Verification (run after EVERY change)
[Adapt to detected stack — example for TypeScript:]
1. `npx tsc --noEmit` — fix ALL type errors
2. `npm test` — fix ALL failing tests
3. `npm run lint` — fix ALL lint errors
4. `npm run build` — confirm it builds

YOU ARE FORBIDDEN from reporting a task as complete until all 4 pass with zero errors. If no test suite exists, say so explicitly instead of claiming success.
```

#### Section 3: Plan Enforcement

```markdown
## Planning Rules
- For ANY non-trivial task (3+ steps or architectural decisions): plan mode FIRST
- Plans MUST list unresolved questions at the end — surface what you don't know
- Never attempt multi-file refactors in one shot. Break into phases of max 5 files each
- Complete Phase N, run verification, get approval BEFORE starting Phase N+1
- If something goes sideways: STOP. Re-plan. Do not keep pushing a broken approach
- If a fix doesn't work after 2 attempts: stop, re-read the full context top-down, identify where your mental model is wrong, and say so before trying again
```

#### Section 4: Code Quality

```markdown
## Code Quality
- Fix root causes, not symptoms. If a display bug tempts you to duplicate state, you're solving the wrong problem
- Before editing ANY file: re-read it first. After editing: read it again to confirm the change applied. The Edit tool fails silently on stale context
- After 10+ messages in a conversation: MUST re-read files before editing. Context decay is real
- No function > 50 lines. No file > 300 lines (split if larger)
- When renaming anything: search for direct calls, type refs, string literals, dynamic imports, re-exports, test mocks. A single grep is never enough
- Don't build for imaginary scenarios. If the solution handles hypothetical future needs nobody asked for, strip it back
- Write code a human would write. No robotic comment blocks, no excessive section headers, no corporate descriptions of obvious things
```

#### Section 5: Testing

```markdown
## Testing
- Write tests BEFORE implementation (RED → GREEN → REFACTOR)
- Fix the implementation to pass the test. NEVER weaken or delete a test to make it pass
- Tests must fail for real defects — no trivial assertions, no testing what the type checker catches
- Use strong assertions (`toEqual(1)` not `toBeGreaterThanOrEqual(1)`)
- Test edge cases, boundaries, and unexpected input — not just the happy path
```

#### Section 6: Self-Improvement (LAST LINES — recency attention)

```markdown
## When Corrected
After ANY correction: ask yourself what rule would prevent this category of mistake in the future. Propose updating this CLAUDE.md. Keep iterating until the mistake rate drops to zero.

## Gotchas
<!-- Add project-specific corrections below as they happen -->
```

---

### Stack-Specific Additions

Based on detected stack, ADD (not replace) these project-specific commands and patterns:

**Python projects** — add:
```markdown
## Commands
- `ruff check src/ tests/` — lint
- `ruff format src/ tests/` — format
- `pytest tests/ -q` — test
- `mypy src/` — typecheck (if configured)
```

**Go projects** — add:
```markdown
## Commands
- `go build ./...` — build
- `go vet ./...` — vet
- `go test ./... -count=1` — test (no cache)
- `golangci-lint run` — lint (if configured)
```

**Rust projects** — add:
```markdown
## Commands
- `cargo build` — build
- `cargo test` — test
- `cargo clippy -- -D warnings` — lint
```

**TypeScript/JavaScript projects** — use detected package manager (npm/pnpm/yarn/bun) and actual script names from package.json.

### What NOT to Include

NEVER add these to the generated CLAUDE.md:
- Standard language conventions Claude already knows
- File-by-file descriptions of the codebase (Claude can read it)
- Detailed API documentation (link to it: "For auth flows, see docs/auth.md")
- Information that changes frequently
- Formatting rules (use .editorconfig, .prettierrc, ruff.toml instead)
- "Write clean code" or other generic platitudes
- Personality/role instructions

## Phase 4: Rules File Generation (Optional)

If the project has domain-specific patterns that would bloat the root CLAUDE.md beyond 80 lines, create scoped rule files in `.claude/rules/`:

```markdown
<!-- .claude/rules/api-conventions.md -->
---
paths:
  - src/api/**
  - src/routes/**
---
[Domain-specific API rules here]
```

This keeps the root CLAUDE.md lean while giving Claude context-specific rules when working in those directories.

## Phase 5: Hooks Recommendation

CLAUDE.md rules are advisory (~80% compliance that degrades with file length). For critical enforcement, recommend hooks:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": { "tool_name": "write", "file_glob": "src/**" },
        "hooks": [{ "type": "command", "command": "[auto-format command for detected stack]" }]
      }
    ],
    "Stop": [
      {
        "hooks": [{ "type": "command", "command": "[test runner] 2>&1 | tail -5; if [ $? -ne 0 ]; then echo '{\"decision\":\"block\",\"reason\":\"Tests failing. Fix before completing.\"}'; fi" }]
      }
    ]
  }
}
```

Explain: "CLAUDE.md rules can be ignored under context pressure. Hooks are deterministic — 100% enforcement. I recommend hooks for your most critical rules."

## Output Format

Present results as:

```
## CLAUDE.md Forge Report

### Project: [name]
### Stack: [detected]
### Existing CLAUDE.md: [found/not found]

### Audit Score: [X/80] — Grade [A-F]
[If existing file found, list specific issues]

### Generated CLAUDE.md
[The complete file, ready to write]

### Recommended Hooks
[Hook configuration if applicable]

### Next Steps
1. Review the generated CLAUDE.md
2. Say "write it" to apply
3. After your next session with Claude: if it makes a mistake, say "update CLAUDE.md so you don't make that mistake again"
4. Repeat. The file compounds in value over time.
```

## Key Principles This Skill Enforces

These are the root causes of every problem this skill was built to solve:

| Problem | Root Cause | Rule That Fixes It |
|---|---|---|
| Claude veers off plan | No separation between plan and build | "Plan ONLY — no code until approved" |
| Half-assed implementations | Default bias toward "simplest approach" | Senior Dev Override in preamble |
| Bandaid fixes | No root-cause requirement | "Fix root causes, not symptoms" |
| Needs immediate refactoring | No verification before "done" | Forced verification gate |
| Scope creep/reduction | No phased execution | "Max 5 files per phase, verify between" |
| Broken after 10+ messages | Context decay | "Re-read files before editing after 10+ messages" |
| Silent edit failures | Stale context in Edit tool | "Re-read before AND after every edit" |
| Tests pass but code is wrong | Weak assertions, test weakening | "NEVER weaken a test. Strong assertions only" |
| Goes in circles on bugs | No escalation rule | "2 failed attempts → stop, rethink, explain what's wrong" |
| Ignores existing patterns | Doesn't read before writing | "Follow References, Not Descriptions" |

## Phase 6: Project Isolation Rules

### Problem: Claude modifies files in OTHER projects

This is a known issue (anthropics/claude-code#5773). Claude's Edit/Write tools can reach any path on the filesystem. The generated CLAUDE.md MUST include:

```markdown
## Project Boundary (CRITICAL)
YOU MUST ONLY modify files within this project directory. NEVER touch files in other projects, home directory configs, or system files unless explicitly asked. If a task seems to require editing files outside this repo, ASK first — do not silently reach into other directories.
```

Additionally, recommend these settings in `.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Edit(~/*)",
      "Write(~/*)",
      "Edit(../*)",
      "Write(../*)"
    ]
  },
  "sandbox": {
    "allowUnsandboxedCommands": false
  }
}
```

And for the user's global `~/.claude/settings.json`, recommend:

```json
{
  "permissions": {
    "deny": [
      "Edit(/Users/*/Desktop/**)",
      "Edit(/Users/*/Documents/**)",
      "Write(/Users/*/Desktop/**)",
      "Write(/Users/*/Documents/**)"
    ]
  }
}
```

Explain: "Sandbox mode restricts Bash writes to the current directory. Permission deny rules block Edit/Write tools from reaching outside. Both layers together give strong isolation."

## Phase 7: Multi-Terminal / Multi-Session Safety

### Problem: One Claude session commits/pushes and clobbers another session's work

This happens when multiple Claude sessions run against the same working directory. The generated CLAUDE.md MUST include:

```markdown
## Git Safety
- NEVER run `git push` without explicit user approval — even if the plan says to push
- NEVER run `git commit` with `-A` or `.` — stage specific files by name only
- NEVER run `git reset --hard`, `git checkout .`, `git clean -f`, or `git stash drop`
- NEVER amend commits — always create new commits
- Before ANY git operation: run `git status` and `git stash list` first to check for concurrent work
- If you see uncommitted changes you didn't create: STOP and ask the user. Another session may be active
```

Also recommend worktree usage for parallel work:

```markdown
### Parallel Sessions
When running multiple sessions on this repo, use `claude --worktree` to isolate each session in its own git worktree. This prevents file edit collisions and git state conflicts between sessions.
```

And recommend this hook to prevent accidental pushes:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": { "tool_name": "Bash", "command_pattern": "git push*" },
        "hooks": [{ "type": "command", "command": "echo '{\"decision\":\"ask\",\"reason\":\"About to push to remote. Confirm this won't clobber another session's work.\"}'" }]
      }
    ]
  }
}
```

## Phase 8: Dead Code Management

### Problem: Claude either keeps dead code (sloppy) OR deletes good un-wired code (destructive)

The generated CLAUDE.md MUST include:

```markdown
## Dead Code Rules
- NEVER delete code that is part of an in-progress feature just because it has no callers yet. Unreferenced code ≠ dead code. Ask: "Was this written recently as part of current work?"
- NEVER leave truly dead code (old functions, commented-out blocks, unused imports) after a refactor. Clean up what you changed
- When unsure if code is dead: search for dynamic references (string-based imports, reflection, config-driven lookups) before deleting. If still unsure, ASK
- NEVER mix dead-code cleanup with feature work in the same commit. Separate concerns
- After deleting code: run the full test suite. If tests fail, the code wasn't dead
```

## Phase 9: Feature-Dev Level Rigor

### Problem: Claude half-asses implementations, skips exploration, and writes code without understanding the codebase

The generated CLAUDE.md MUST include a rigor section when the project has significant existing code:

```markdown
## Development Rigor
- Before writing ANY new feature code: READ the existing codebase patterns first. Trace at least one similar feature end-to-end (route → handler → service → data layer) to understand the architecture
- Match existing patterns EXACTLY. If the codebase uses repository pattern, use repository pattern. If it uses service classes, use service classes. Do not invent a new pattern
- Every new function must have a CALLER. Never write code that isn't wired into the system. If you create a utility, show where it's used. If you create an API endpoint, show how it's reached
- After implementing: trace the full data path from entry point to storage and back. Verify every connection exists. "I wrote the function" is not done — "the function is called and the data flows through" is done
- For features touching 3+ files: use subagents to keep context clean. One agent per concern (e.g., one for backend, one for frontend, one for tests)
```

## Phase 10: Self-Improving CLAUDE.md That Stays Lean

### Problem: CLAUDE.md grows bloated from corrections until Claude ignores it entirely

The generated CLAUDE.md MUST include a maintenance protocol. Add these instructions to the `## When Corrected` section:

```markdown
## When Corrected
After ANY correction from the user:
1. Identify the CATEGORY of mistake (not just the specific instance)
2. Check if an existing rule already covers this category — if so, SHARPEN that rule instead of adding a new one
3. If genuinely new: propose a single concrete rule using MUST/NEVER + the positive alternative
4. NEVER let this file exceed 80 lines. If adding a rule would exceed 80 lines:
   - Graduate the least-violated rule to a `.claude/rules/` scoped file
   - Or consolidate 2-3 similar rules into one tighter rule
   - Or delete a rule that Claude now follows consistently (it has been internalized)
5. Rules that Claude violates MOST go at the TOP and BOTTOM of this file (primacy + recency attention)
```

Additionally, recommend a monthly CLAUDE.md review prompt:

```
Audit prompt: "Review this CLAUDE.md. For each line, answer: (1) Did Claude violate this in the last 5 sessions? (2) Would Claude make this mistake without the rule? If both answers are no, the rule is dead weight — cut it."
```

### The Budget Is Flexible — But Smart

The 80-line target is for GENERIC projects. **Domain-critical projects (medical, security, financial, legal) legitimately need more.** The goal is not arbitrary line-cutting — it's ensuring every line gets followed.

**The real rule: keep the ROOT CLAUDE.md as lean as possible, and use `.claude/rules/` with path scoping for domain-specific overflow.**

| Project Type | Root CLAUDE.md | .claude/rules/ | Total |
|---|---|---|---|
| Simple app | ~50-80 lines | 0-2 files | ~80 lines |
| Medium project | ~60-80 lines | 3-5 scoped files | ~200 lines |
| Complex domain (medical, finance) | ~80-100 lines | 5-10+ scoped files | 300+ lines OK |

The key insight: path-scoped rules only load when Claude works in matching directories, so they don't compete for attention with the root file.

### NEVER-PRUNE Classification (CRITICAL)

Before suggesting ANY removal or consolidation, classify every rule into one of these categories:

**PROTECTED (never remove, never consolidate, never weaken):**
- Security invariants ("NEVER store plaintext PHI", "ALL gates deterministic")
- Data governance / single source of truth rules (table mappings, canonical storage locations)
- Encryption / PHI / PII handling rules (tier architecture, anonymization pipelines)
- Medical / legal / compliance requirements
- Specific function/module names that MUST be called (project-specific required APIs, validation gates)
- Safety-critical "NEVER do X" rules with known consequences
- Cross-platform parity requirements
- Architecture decisions that prevent data loss

**MOVABLE (safe to relocate to `.claude/rules/` but never delete):**
- Module-specific rules (PDF pipeline rules → `.claude/rules/pdf-pipeline.md`)
- Background task/scheduler rules → `.claude/rules/scheduler.md`
- LLM/model routing rules → `.claude/rules/llm-routing.md`
- Test-specific conventions → `.claude/rules/testing.md`

**CONSOLIDATABLE (safe to merge similar rules into tighter versions):**
- Multiple rules saying the same thing differently
- Rules that overlap with other rules
- Verbose explanations that can be tightened without losing meaning

**PRUNABLE (safe to remove entirely):**
- Generic advice Claude follows without the rule
- Information Claude can discover by reading code
- Stale references to deleted files/functions (verify first!)
- Formatting rules that belong in linter config
- Personality instructions

### Smart Migration for Large CLAUDE.md Files

When a project has a large CLAUDE.md (100+ lines) that contains critical domain knowledge:

**Step 1: Classify every section** using the NEVER-PRUNE categories above

**Step 2: Keep in root CLAUDE.md** — PROTECTED rules only, plus:
- Product vision (1-3 lines)
- Design priorities (3-5 lines)
- Verification commands
- Cross-cutting rules that apply everywhere
- "What NOT to do" safety rules
- Isolation rule

**Step 3: Migrate MOVABLE rules** to path-scoped `.claude/rules/` files:

```markdown
<!-- .claude/rules/security.md -->
---
paths:
  - src/security/**
  - src/ingest/**
  - src/llm/**
---
## Security Invariants
[Relocated security rules — COMPLETE, nothing removed]
```

```markdown
<!-- .claude/rules/data-governance.md -->
---
paths:
  - src/data/**
  - src/db/**
  - src/reasoning/**
---
## Data Governance
[Relocated data rules — COMPLETE, nothing removed]
```

**Step 4: Create reference docs** for detailed knowledge:

```markdown
## References (in root CLAUDE.md)
- For PDF pipeline rules: see `.claude/rules/pdf-pipeline.md`
- For scheduler/task rules: see `.claude/rules/scheduler.md`
- For LLM model routing: see `.claude/rules/llm-routing.md`
- For architecture details: see `docs/claude/ARCHITECTURE.md`
```

**Step 5: VERIFY nothing was lost** — diff the original file against the sum of all new files. Every original line must exist somewhere. Present the diff to the user for approval.

### Rules WITHOUT paths: frontmatter load EVERY session

IMPORTANT: Only add `paths:` frontmatter to rules that are truly domain-scoped. Rules without `paths:` load globally with the same priority as CLAUDE.md. For critical cross-cutting rules (security, data governance), you may WANT them to load globally — just put them in `.claude/rules/` without `paths:` to reduce root file size while keeping global visibility.

### The Progressive Disclosure Pattern

For projects with extensive documentation in separate files:

```markdown
## References (in root CLAUDE.md)
> Detailed docs: [Installation](docs/INSTALLATION.md) · [Commands](docs/COMMANDS.md) · [Architecture](docs/ARCHITECTURE.md)

IMPORTANT: Before starting any task, identify which docs above are relevant and read them first.
```

This costs ~2 lines in the root file but gives Claude access to thousands of lines of context ON DEMAND. The "IMPORTANT" keyword ensures Claude actually reads the relevant docs before working.

## Phase 11: Settings.json Recommendations

Beyond CLAUDE.md, recommend these settings to the user based on their issues:

### Prevent accidental pushes and destructive git ops

```json
{
  "permissions": {
    "ask": [
      "Bash(git push *)",
      "Bash(git reset *)",
      "Bash(git checkout -- *)",
      "Bash(git clean *)",
      "Bash(git stash drop *)"
    ]
  }
}
```

### Auto-format on write (prevents lint failures)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": { "tool_name": "write", "file_glob": "**/*.py" },
        "hooks": [{ "type": "command", "command": "ruff format $CLAUDE_FILE_PATH 2>/dev/null; ruff check --fix $CLAUDE_FILE_PATH 2>/dev/null" }]
      },
      {
        "matcher": { "tool_name": "write", "file_glob": "**/*.{ts,tsx,js,jsx}" },
        "hooks": [{ "type": "command", "command": "npx prettier --write $CLAUDE_FILE_PATH 2>/dev/null" }]
      }
    ]
  }
}
```

### Stop hook — block completion when tests fail

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [{
          "type": "command",
          "command": "cd $CLAUDE_PROJECT_DIR && [TEST_COMMAND] 2>&1 | tail -5; if [ $? -ne 0 ]; then echo '{\"decision\":\"block\",\"reason\":\"Tests are failing. Fix before completing.\"}'; fi"
        }]
      }
    ]
  }
}
```

## Updated Output Format

Present results as:

```
## CLAUDE.md Forge Report

### Project: [name]
### Stack: [detected]
### Existing CLAUDE.md: [found/not found]

### Audit Score: [X/80] — Grade [A-F]
[If existing file found, list specific issues by category]

### Generated CLAUDE.md
[The complete file, ready to write — MUST be under 80 lines]

### Scoped Rules (if needed)
[Any .claude/rules/*.md files for domain-specific overflow]

### Recommended settings.json
[Permission deny rules, hooks, sandbox config]

### Recommended Hooks
[PostToolUse auto-format, Stop verification gate, PreToolUse git safety]

### Next Steps
1. Review the generated CLAUDE.md — every line should feel necessary
2. Say "write it" to apply all files
3. Run `/xforge audit` monthly to check for bloat
4. After corrections: "update CLAUDE.md so you don't make that mistake again"
5. For parallel work: always use `claude --worktree` to isolate sessions
6. The file compounds in value over time — but only if you keep it lean
```

## Complete Problem → Solution Map

| Problem | Root Cause | Rule That Fixes It |
|---|---|---|
| Claude veers off plan | No separation between plan and build | "Plan ONLY — no code until approved" |
| Half-assed implementations | Default bias toward "simplest approach" | Senior Dev Override in preamble |
| Bandaid fixes | No root-cause requirement | "Fix root causes, not symptoms" |
| Needs immediate refactoring | No verification before "done" | Forced verification gate |
| Scope creep/reduction | No phased execution | "Max 5 files per phase, verify between" |
| Broken after 10+ messages | Context decay | "Re-read files before editing after 10+ messages" |
| Silent edit failures | Stale context in Edit tool | "Re-read before AND after every edit" |
| Tests pass but code is wrong | Weak assertions, test weakening | "NEVER weaken a test. Strong assertions only" |
| Goes in circles on bugs | No escalation rule | "2 failed attempts → stop, rethink, explain" |
| Ignores existing patterns | Doesn't read before writing | "Read codebase patterns before writing new code" |
| Modifies other projects | No file boundary enforcement | Project boundary rule + permission deny rules |
| Multi-terminal clobbers work | No git safety rules | Git safety rules + worktree isolation |
| Deletes good un-wired code | Can't distinguish WIP from dead code | "Unreferenced ≠ dead. Ask if recent" |
| Keeps actual dead code | No cleanup requirement | "Clean up what you changed. Separate commits" |
| CLAUDE.md gets ignored | File too long, instructions diluted | Smart budget + monthly audit + graduated rules |
| New features don't match codebase | No exploration before writing | "Trace one similar feature e2e before building" |
| Code written but not wired | No caller requirement | "Every function must have a caller" |
| Pruning destroys critical rules | No rule classification before pruning | NEVER-PRUNE classification (PROTECTED/MOVABLE/PRUNABLE) |
| Complex project needs 200+ lines | One-size-fits-all line limit | Smart migration to .claude/rules/ with path scoping |

## References for Deep Dives

- Anthropic official: `code.claude.com/docs/en/memory` and `code.claude.com/docs/en/best-practices`
- Anthropic settings: `code.claude.com/docs/en/settings`
- Anthropic sandboxing: `anthropic.com/engineering/claude-code-sandboxing`
- Boris Cherny's tips: `howborisusesclaudecode.com`
- ETH Zurich research: verbose context files reduce agent performance while increasing costs
- Instruction budget: ~150-200 total instructions reliable; Claude Code system prompt uses ~50; your CLAUDE.md gets ~100-150 slots
- Cross-project issue: `github.com/anthropics/claude-code/issues/5773`
- Worktree guide: `claudefa.st/blog/guide/development/worktree-guide`
- Self-improving seed: `gist.github.com/ChristopherA/fd2985551e765a86f4fbb24080263a2f`
- Anti-slop rules: `github.com/iamfakeguru/claude-md`
- Community best practices: `github.com/shanraisshan/claude-code-best-practice`
