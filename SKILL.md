---
name: xforge
description: "Xinu's ClaudeMD Fix — audit, score, improve, and generate battle-tested CLAUDE.md instruction architectures that enforce plan adherence, prevent bandaid fixes, and eliminate refactoring debt."
origin: custom
---

# Xinu's ClaudeMD Fix

Design CLAUDE.md instruction architectures — not just files. Decides what belongs in root CLAUDE.md vs `.claude/rules/` vs `.claude/skills/` vs hooks vs `CLAUDE.local.md`. Based on Anthropic's official guidance for memory, rules, hooks, skills, settings, and sandboxing, plus battle-tested anti-slop patterns from real production setups.

## When to Activate

- `/xforge` — full pipeline: backup → score → grade-based improve/generate → present diff for approval
- `/xforge score` — read-only health check: grade, 8-criteria breakdown, line-by-line classification, placement analysis. Changes NOTHING
- `/xforge new` — generate fresh CLAUDE.md instruction architecture from scratch
- When user says "improve my claude md", "fix my claude.md", "my claude.md sucks", "claude keeps ignoring rules"

**Auto-detection**: When run outside a git repo or when no project CLAUDE.md exists, xforge targets `~/.claude/CLAUDE.md` instead.

### `/xforge score` Output Format

```
## CLAUDE.md Health Check

**Project**: [name] | **Stack**: [detected] | **Lines**: [count]
**Score**: [X/80] — **Grade [A-F]**

### 8-Criteria Breakdown
| Criteria | Score | Notes |
|---|---|---|
| Conciseness | X/10 | [1-line note] |
| Verification Commands | X/10 | ... |
| Anti-Slop Rules | X/10 | ... |
| Plan Enforcement | X/10 | ... |
| Specificity | X/10 | ... |
| No Redundancy | X/10 | ... |
| Positive Framing | X/10 | ... |
| Architecture Clarity | X/10 | ... |

### Line-by-Line Classification
Line 5: "All endpoints must validate..." → LOAD-BEARING (keep) → ROOT
Line 12: "Write clean code" → GENERIC → PRUNE
Line 18: "NEVER store plaintext PHI" → PROTECTED (never touch) → ROOT
Line 25: "Use the repo pattern" → VAGUE → ROOT (rewrite with paths)
Line 30: "PDF pipeline must sanitize..." → LOAD-BEARING → RULE (move to .claude/rules/pdf.md)
Line 40: "Deploy checklist: ..." → LOAD-BEARING → SKILL (move to .claude/skills/deploy/)
Line 45: "Auto-format on save" → ENFORCEMENT → HOOK (use PostToolUse hook)
Line 50: "My local DB is on port 5433" → PERSONAL → LOCAL (move to CLAUDE.local.md)

### Placement Recommendations
| Current Location | Recommended | Lines | Reason |
|---|---|---|---|
| Root CLAUDE.md | .claude/rules/api.md | 12-18 | Path-scoped to src/api/ |
| Root CLAUDE.md | .claude/skills/deploy/ | 40-55 | Heavy workflow, load on demand |
| Root CLAUDE.md | Hook (PostToolUse) | 45 | Deterministic — prose can't enforce this |
| Root CLAUDE.md | CLAUDE.local.md | 50-52 | Machine-specific, not for git |

### Top 3 Issues
1. [Most impactful — 1 sentence]
2. [Second — 1 sentence]
3. [Third — 1 sentence]

### What's Working
- [1-2 things the file does well]

### Next Step
Run `/xforge` to auto-fix (backs up your file first).
```

## Phase 0: Mandatory Backup (SKIP for `/xforge score`)

**SKIP THIS PHASE ENTIRELY for `/xforge score`.** Score is read-only.

For `/xforge` and `/xforge new` only — before touching ANY file:

```
cp CLAUDE.md "CLAUDE.md.backup.$(date +%Y%m%d-%H%M%S)" 2>/dev/null
cp .claude/CLAUDE.md ".claude/CLAUDE.md.backup.$(date +%Y%m%d-%H%M%S)" 2>/dev/null
tar czf ".claude/rules-backup-$(date +%Y%m%d-%H%M%S).tar.gz" .claude/rules/ 2>/dev/null
```

Tell the user: "Backed up your existing files. If anything goes wrong, your originals are preserved with timestamps."

### Do No Harm Principle

After generating or improving, BEFORE writing:

1. **Compare original vs proposed** — read both side by side
2. **For every line REMOVED**: confirm it was genuinely dead weight, not a hard-won project rule. If unsure, KEEP IT
3. **For every line CHANGED**: confirm the new version is strictly more specific, not vaguer
4. **For every line ADDED**: confirm it passes the load-bearing test — does Claude actually need this to avoid a mistake?
5. **Ask yourself**: "If the user runs this in their next 5 sessions, will Claude behave BETTER or WORSE?" If ANY doubt, present as suggestions
6. **Present a diff** showing exactly what changed and why. Never silently rewrite

If the original is grade A or B, recommend targeted improvements — a scalpel, not a sledgehammer.

## Phase 1: Project Discovery

Scan the project before writing a single rule:

1. **Language and framework** — package.json, Cargo.toml, go.mod, pyproject.toml, Makefile, etc.
2. **Build/test/lint commands** — scripts section, Makefile targets, tool configs
3. **Existing CLAUDE.md and rules** — read CLAUDE.md, .claude/CLAUDE.md, list .claude/rules/, check for CLAUDE.local.md
4. **Project structure** — glob for source files to understand the stack
5. **Test framework** — tests/, __tests__/, spec/ directories
6. **Git setup** — remote, recent commits, branching pattern
7. **Existing skills** — list .claude/skills/ to avoid duplicating workflows

## Phase 2: Audit & Placement Analysis

### Scoring Criteria (0-10 each, 80 max)

| Criteria | What to Check |
|---|---|
| **Conciseness** | Appropriate size for project complexity? Every line passes the load-bearing test? |
| **Verification Commands** | Has copy-paste-ready build/test/lint commands? |
| **Anti-Slop Rules** | Has rules preventing bandaids, scope drift, half-implementations? |
| **Plan Enforcement** | Has rules separating plan from build, requiring approval? |
| **Specificity** | Rules are concrete and verifiable, not vague? |
| **No Redundancy** | No rules Claude can infer from code? No duplicating linter territory? |
| **Positive Framing** | Every "don't X" has a "do Y instead"? |
| **Architecture Clarity** | Non-obvious patterns, gotchas, and decisions documented? |

### Placement Framework

For every rule or instruction, classify WHERE it belongs:

| Classification | Best Home | When to Use |
|---|---|---|
| **ROOT** | Root `CLAUDE.md` | Broad always-on behavior: verification, anti-slop, planning, project boundary, git safety |
| **RULE** | `.claude/rules/*.md` | Path-scoped or domain-scoped policies. Use `paths:` frontmatter for directory filtering. Rules WITHOUT `paths:` load globally — useful for cross-cutting rules that reduce root file size |
| **SKILL** | `.claude/skills/<name>/SKILL.md` | Heavy repeatable workflows (release, migration, audit, compliance). Loaded on demand via slash command, not every session |
| **HOOK** | Hooks in settings.json or `.claude/hooks/` | Deterministic enforcement: auto-format, push guards, completion gates, test runners. Prose cannot reliably enforce these — use hooks |
| **LOCAL** | `CLAUDE.local.md` | Personal, temporary, or machine-specific: local ports, custom paths, WIP notes. Gitignored by convention |
| **PRUNE** | Remove entirely | Generic advice, stale references, linter territory, personality instructions, info Claude can discover from code |

### Anti-Patterns to Flag

Flag and fix these if found:

- **Personality instructions** ("Act as a senior engineer") — wastes tokens, Claude has strong system directives
- **Generic advice** ("Write clean code", "Use meaningful names") — obvious, wastes budget
- **Stale `@imports`** — blind imports of large/changing files dilute context. But targeted `@imports` of stable docs are fine (architecture docs, API references, package manifests). Max import depth is 5 hops (official limit)
- **Code snippets in CLAUDE.md** — go stale fast; use `file:line` references instead
- **Formatting rules** — belong in .editorconfig/.eslintrc/.prettierrc, not CLAUDE.md
- **Duplicate rules** — each rule in exactly one place
- **Directory listings** — Claude can read the project
- **Stale references** — commands/paths that no longer exist (verify before flagging!)
- **Root file over ~200 lines** — official guidance is under 200 lines per CLAUDE.md file. Start moving content to rules/skills/hooks

### Quality Gate

- **A (65-80)**: Production-grade, ship it
- **B (50-64)**: Good foundation, minor improvements needed
- **C (35-49)**: Mediocre, significant gaps — rewrite recommended
- **D (20-34)**: More harm than good — delete and regenerate
- **F (0-19)**: Actively hurting Claude — nuke from orbit

### Decision Point: What to Do Based on Grade

**Grade A (65-80)** — DO NOT REWRITE. Only:
  - Add missing sections (e.g., no verification commands? Add them)
  - Tighten vague lines to be more specific
  - Suggest placement migration IF over ~150 lines
  - Present changes as a SHORT diff

**Grade B (50-64)** — TARGETED IMPROVEMENTS only:
  - Add missing mandatory sections
  - Sharpen vague rules with project-specific details from Phase 1
  - Do NOT remove or rewrite existing project-specific rules
  - Present as diff with clear before/after

**Grade C (35-49)** — REWRITE RECOMMENDED but preserve project-specific rules:
  - Keep every PROTECTED and MOVABLE rule (per NEVER-PRUNE)
  - Restructure around mandatory sections
  - Fill gaps with stack-appropriate rules from Phase 1

**Grade D/F (0-34)** — FULL REWRITE justified:
  - Generate fresh using Phase 3 template
  - Scan old file for project-specific knowledge worth saving

**For `/xforge score`**: Only run Phases 1, 2. Output the full report — change NOTHING.

### NEVER-PRUNE Classification

Before suggesting ANY removal, classify every rule:

**PROTECTED (never remove, never consolidate, never weaken):**
- Security invariants, encryption/PHI/PII rules, data governance
- Medical/legal/compliance requirements
- Specific function/module names that MUST be called
- Safety-critical "NEVER do X" rules with known consequences
- Architecture decisions that prevent data loss

**MOVABLE (safe to relocate but never delete):**
- Module-specific rules → path-scoped `.claude/rules/` files
- Domain workflows → `.claude/skills/`
- Deterministic checks → hooks

**CONSOLIDATABLE (safe to merge):**
- Multiple rules saying the same thing differently
- Verbose explanations that can be tightened

**PRUNABLE (safe to remove):**
- Generic advice Claude follows without the rule
- Info Claude can discover by reading code
- Stale references to deleted files/functions (verify first!)
- Formatting rules that belong in linter config
- Personality instructions

### Make Every Line Load-Bearing

For each line, apply this decision tree:

1. **Project-specific knowledge Claude cannot infer from code?** YES → Keep. NO → candidate for removal
2. **Concrete and verifiable?** "Always validate inputs" → rewrite to "All API endpoints MUST validate with [schema lib]"
3. **Missing context Claude needs?** Add build commands, test runners, architectural patterns, known gotchas
4. **Duplicating what a linter/formatter enforces?** Remove from CLAUDE.md, confirm tool config exists
5. **Has a positive alternative?** "Don't use X" → "Don't use X — use Y instead"

## Phase 3: Generate / Rewrite CLAUDE.md

### Budget Rules

The root CLAUDE.md target depends on project complexity. The official Anthropic guidance is under 200 lines per file:

| Project Type | Root CLAUDE.md | .claude/rules/ | Notes |
|---|---|---|---|
| Simple app | ~50-80 lines | 0-2 files | Most rules fit in root |
| Medium project | ~80-120 lines | 3-5 scoped files | Domain rules migrate to .claude/rules/ |
| Complex domain (medical, finance, legal) | ~100-150 lines | 5-10+ scoped files | PROTECTED rules stay in root, domain rules scope out |

**Hard warning**: if any single always-on file approaches ~200 lines, aggressively move content to rules/skills/hooks. Path-scoped rules only load when Claude works in matching directories, so they don't compete for attention with the root file.

Every line must pass this test: **"Would removing this cause Claude to make a wrong decision it couldn't recover from by reading the code?"** If no, cut it or move it to a better layer.

### Mandatory Sections (adapted to project stack)

The generated CLAUDE.md MUST include ALL of these, adapted to the project:

---

#### Section 1: Anti-Slop Preamble (FIRST 5 LINES — highest attention)

```markdown
# [Project Name]

IMPORTANT: You have two failure modes and BOTH are defects.
- Mode 1 — SKIPPING: dropping requirements, implementing skeletons, leaving TODOs, saying "you can add this later", doing 3 of 5 requested items. This is the MORE COMMON failure.
- Mode 2 — BLOATING: adding unrequested features, unnecessary abstractions, speculative error handling, helper functions for one-time operations, docstrings on code you didn't write.
Do EXACTLY what was asked. No more, no less. If the task is complex, the implementation is complex — do not simplify the TASK. Simplify the CODE that implements the full task. Fix root causes, not symptoms. No temporary fixes. No "simplified versions."

YOU MUST separate planning from building. For anything beyond a single, obvious change: read the relevant code first, then present a plan with phases and unresolved questions BEFORE writing any code. Do this AUTOMATICALLY — do not wait for the user to say "plan first." The user should be able to say "build me X" and you respond with a plan, not code. No code until the plan is approved. When following a plan: execute it exactly. If you spot a problem, flag it and WAIT — do not improvise or reduce scope.
```

#### Section 2: Verification Commands

```markdown
## Verification (run after EVERY change)
[Adapt to detected stack — example for TypeScript:]
1. `npx tsc --noEmit` — fix ALL type errors
2. `npm test` — fix ALL failing tests
3. `npm run lint` — fix ALL lint errors
4. `npm run build` — confirm it builds

YOU ARE FORBIDDEN from reporting a task as complete until all checks pass with zero errors. If a check is unavailable (no test suite, no linter configured), say so explicitly — report what you ran and what remains manual.
```

**Iteration vs completion**: During iteration, run the smallest meaningful check (typecheck, single test file). Before claiming DONE, run the full verification chain. Both are required — the difference is scope and timing.

#### Section 3: Plan Enforcement + Recovery

```markdown
## Planning Rules
- For anything beyond a single obvious change: AUTOMATICALLY read the relevant codebase, then present a plan BEFORE writing code. Do NOT wait for the user to tell you to plan — just do it. The user says "build me X" and your first response is a plan, not code
- Plans MUST account for EVERY requirement in the request. If the user asked for 5 things, the plan has 5+ items. Missing items = broken plan
- Plans MUST list unresolved questions — surface what you don't know
- Break work into phases. Each phase: max 5 files. Complete a phase, run verification, self-audit ("does every piece connect? is anything orphaned?"), then move on
- If something goes sideways: STOP. Re-plan. Do not keep pushing a broken approach
- If a fix doesn't work after 2 attempts: stop, re-read the full context top-down, identify where your mental model is wrong, and say so. If still stuck, recommend `/clear` and a fresh approach rather than thrashing
- Before claiming done: re-read the original request. Verify EVERY item was addressed. Unaddressed items = not done
```

#### Section 4: Code Quality

```markdown
## Code Quality
- Fix root causes, not symptoms. If a display bug tempts you to duplicate state, you're solving the wrong problem
- Before editing ANY file: re-read it first. After editing: read it again to confirm the change applied. The Edit tool fails silently on stale context
- After 10+ messages in a conversation: MUST re-read files before editing. Context decay is real
- Prefer functions under 50 lines and files under 300 lines — but these are GUIDELINES, not hard limits. Complex logic that is clearer as one longer function stays as one function. Never split or simplify working code just to hit a line count
- NEVER truncate, stub out, or "simplify" an implementation because it is getting long. If the task requires 500 lines, write 500 lines. "This is getting complex, let me simplify" when the complexity is inherent to the problem is a DEFECT
- Don't add features, refactor code, or make "improvements" beyond what was asked. A bug fix doesn't need surrounding code cleaned up
- Don't create helpers, utilities, or abstractions for one-time operations. Three similar lines of code is better than a premature abstraction
- Don't add docstrings, comments, or type annotations to code you didn't change
- Don't build for imaginary scenarios. No speculative error handling, no hypothetical future needs, no "just in case" code
- When renaming anything: search for direct calls, type refs, string literals, dynamic imports, re-exports, test mocks. A single grep is never enough
```

#### Section 5: Testing

```markdown
## Testing
- Write tests BEFORE implementation (RED → GREEN → REFACTOR)
- Fix the implementation to pass the test. NEVER weaken or delete a test to make it pass
- Tests must fail for real defects — no trivial assertions, no testing what the type checker catches
- Test edge cases, boundaries, and unexpected input — not just the happy path
- A unit test that mocks everything proves NOTHING about whether the feature works. Test the FULL data path: request → validation → handler → service → storage → response. If you can't test end-to-end, test the largest real slice you can and say what's untested
- "Tests pass" means the FEATURE works, not that individual functions return expected values in isolation. If you added an API endpoint, call it. If you added a data pipeline, feed it real input and verify output
```

#### Section 6: Project Boundary + Git Safety

```markdown
## Project Boundary
YOU MUST ONLY modify files within this project directory. NEVER touch files in other projects or system files unless explicitly asked. If a task seems to require editing outside this repo, ASK first.

## Git Safety
- NEVER `git push` without explicit user approval
- NEVER `git commit` with `-A` or `.` — stage specific files by name
- NEVER `git reset --hard`, `git checkout .`, `git clean -f`
- NEVER amend commits — always create new commits
- If you see uncommitted changes you didn't create: STOP and ask. Another session may be active
- For parallel sessions: use `claude --worktree` to isolate in separate git worktrees
```

#### Section 7: Wiring Verification + Anti-Silent-Failure

```markdown
## Wiring Verification (before claiming ANY feature works)
- Prove the FULL path is connected: route registered → handler called → service invoked → data persisted → response returned
- Check for: unregistered routes, unattached event handlers, unread config, swallowed errors, unrendered components, unscheduled jobs, missing middleware
- NEVER say "now it supports X" unless you can show the code path where X actually executes end-to-end
- Every new function must have a CALLER. Never write code that isn't wired into the system
- NEVER leave TODO comments, placeholder functions, or "implement later" stubs. If you write it, finish it. If you can't finish it, say so explicitly — don't leave a skeleton and call it done
- Before writing new code: trace at least one similar feature e2e to understand existing patterns. Match them EXACTLY — same directory structure, same naming conventions, same patterns. Do not invent a new pattern when the codebase already has one

## Dead Code
- Unreferenced code ≠ dead code. If recently written as part of current work, it's WIP — ask before deleting
- After a refactor: clean up what you changed. Don't leave truly dead code behind
- NEVER mix dead-code cleanup with feature work in the same commit
```

#### Section 8: Self-Improvement (LAST LINES — recency attention)

```markdown
## When Corrected
After ANY correction:
1. Identify the CATEGORY of mistake (not just the specific instance)
2. Check if an existing rule covers it — SHARPEN that rule instead of adding a new one
3. If genuinely new: propose a single concrete rule using MUST/NEVER + the positive alternative
4. If adding a rule would push the root file past its budget: graduate the least-violated rule to `.claude/rules/`, consolidate similar rules, or remove a consistently-followed rule
5. Rules that Claude violates MOST go at the TOP and BOTTOM (primacy + recency attention)

## Gotchas
[Add project-specific corrections below as they happen]
```

---

### Stack-Specific Additions

Based on detected stack, ADD these verification commands:

**Python**: `ruff check src/ tests/` + `ruff format src/ tests/` + `pytest tests/ -q` + `mypy src/` (if configured)

**Go**: `go build ./...` + `go vet ./...` + `go test ./... -count=1` + `golangci-lint run` (if configured)

**Rust**: `cargo build` + `cargo test` + `cargo clippy -- -D warnings`

**TypeScript/JavaScript**: use detected package manager and actual script names from package.json.

### What NOT to Include

NEVER add these to the generated CLAUDE.md:
- Standard language conventions Claude already knows
- File-by-file descriptions of the codebase (Claude can read it)
- Detailed API documentation (use `@docs/auth.md` imports for stable reference docs, or "For auth flows, see docs/auth.md")
- Information that changes frequently (put in CLAUDE.local.md or auto memory)
- Formatting rules (use .editorconfig, .prettierrc, ruff.toml)
- "Write clean code" or other generic platitudes
- Personality/role instructions

### The Progressive Disclosure Pattern

For projects with extensive documentation:

```markdown
## References
> [Installation](docs/INSTALLATION.md) · [Commands](docs/COMMANDS.md) · [Architecture](docs/ARCHITECTURE.md)

IMPORTANT: Before starting any task, identify which docs above are relevant and read them first.
```

This costs ~2 lines but gives Claude access to thousands of lines ON DEMAND.

Targeted `@import` of stable docs (architecture decisions, API specs, package manifests) is good practice. Blind `@import` of large or frequently-changing files wastes context. The official import depth limit is 5 hops.

## Phase 4: Rules File Generation

If the project has domain-specific rules that would push the root CLAUDE.md past its budget, create scoped rule files:

```markdown
# .claude/rules/api-conventions.md
---
paths:
  - src/api/**
  - src/routes/**
---
[Domain-specific API rules here]
```

**Rules WITHOUT `paths:` frontmatter load EVERY session** with the same priority as CLAUDE.md. Use this intentionally for cross-cutting rules (security, data governance) that should always be active but don't need to dilute the root file.

### Smart Migration for Large Files

When migrating a large CLAUDE.md:

1. **Classify every section** using NEVER-PRUNE categories
2. **Keep in root**: PROTECTED rules, product vision (1-3 lines), verification commands, cross-cutting rules, safety rules
3. **Migrate MOVABLE rules** to path-scoped `.claude/rules/` files
4. **Create reference links** in root: "For PDF pipeline rules: see `.claude/rules/pdf-pipeline.md`"
5. **VERIFY nothing was lost** — diff original against sum of all new files. Every original line must exist somewhere. Present diff to user

## Phase 5: Project Skill Generation

When a workflow is too large, specialized, or occasional for root CLAUDE.md or rules, recommend a project-local skill.

### When to Recommend Skills

- Release/deploy checklists (5+ steps with verification gates)
- Migration workflows (schema, data, version upgrades)
- Feature audit or security review procedures
- PHI/billing/compliance workflows with specific legal requirements
- Onboarding guides that don't need to load every session

### Skill Template

```markdown
# .claude/skills/deploy/SKILL.md
---
name: deploy
description: "Production deployment workflow with verification gates"
user-invocable: true
---

# Deploy to Production

## Pre-Deploy Checks
1. `npm test` — all tests pass
2. `npm run build` — clean build
3. `git status` — no uncommitted changes
4. Verify CHANGELOG.md updated

## Deploy Steps
[Project-specific deploy procedure]

## Post-Deploy Verification
[Health checks, smoke tests, rollback criteria]
```

Skills load on demand via `/deploy`, not every session. This keeps the root CLAUDE.md lean while preserving complex workflows.

## Phase 6: Install Hooks

CLAUDE.md rules are advisory. Hooks are deterministic — use hooks for enforcement that prose cannot reliably guarantee.

**xforge MUST install hooks, not just recommend them.** During `/xforge` and `/xforge new`:
1. Read the existing `.claude/settings.json` (create if missing)
2. Merge the hooks below with any existing hooks (do not overwrite user's existing hooks)
3. Present the diff to the user: "These hooks will be added to enforce your most critical rules"
4. On approval, write the merged settings
5. For `/xforge score`: only SHOW what hooks are missing — do not install

### Safe Hook Patterns

For non-trivial hook logic, prefer script files in `.claude/hooks/` over inline shell:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": { "tool_name": "Write|Edit", "file_glob": "**/*.py" },
        "hooks": [{
          "type": "command",
          "command": "cd \"$CLAUDE_PROJECT_DIR\" && ruff format \"$CLAUDE_TOOL_INPUT_FILE_PATH\" 2>/dev/null; ruff check --fix \"$CLAUDE_TOOL_INPUT_FILE_PATH\" 2>/dev/null; true"
        }]
      }
    ],
    "PreToolUse": [
      {
        "matcher": { "tool_name": "Bash", "command_pattern": "git push" },
        "hooks": [{
          "type": "command",
          "command": "echo '{\"decision\":\"ask\",\"reason\":\"About to push to remote. Confirm this is intentional.\"}'"
        }]
      }
    ]
  }
}
```

### Stop Hook — Completion Gate

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [{
          "type": "command",
          "command": "cd \"$CLAUDE_PROJECT_DIR\" && TEST_EXIT=0; [TEST_COMMAND] >/dev/null 2>&1 || TEST_EXIT=$?; if [ \"$TEST_EXIT\" -ne 0 ]; then echo '{\"decision\":\"block\",\"reason\":\"Tests failing. Fix before completing.\"}'; fi"
        }]
      }
    ]
  }
}
```

Note: capture the test command's exit code BEFORE piping — `cmd | tail` loses the original exit code.

### When to Use Script-Based Hooks

When hook logic gets non-trivial (conditionals, multiple commands, path validation), move it to a script:

```bash
# .claude/hooks/pre-push-check.sh
#!/bin/bash
set -euo pipefail
cd "$CLAUDE_PROJECT_DIR"

# Skip if not in a git repo
[ -d .git ] || exit 0

# Warn about uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
  echo '{"decision":"ask","reason":"Uncommitted changes detected. Push anyway?"}'
fi
```

Reference from settings: `"command": "bash .claude/hooks/pre-push-check.sh"`

### Hook vs Prose Decision Guide

| Need | Use Hook? | Why |
|---|---|---|
| Auto-format after write | Yes | Deterministic, no exceptions |
| Block push without approval | Yes | Safety-critical gate |
| Block completion when tests fail | Yes | Prevents false "done" claims |
| "Prefer small functions" | No — prose | Judgment call, not enforceable |
| "Plan before coding" | No — prose | Requires reasoning, not a gate |
| "Read file before editing" | Consider prompt hook | Can remind Claude, but not force |

**Prompt hooks** send to Claude for yes/no evaluation — useful when richer reasoning is needed than inline shell can provide. **Agent hooks** spawn subagents with tool access (Read, Grep, Glob) for complex validation.

## Phase 7: Install Settings & Security

**xforge MUST install these settings, not just recommend them.** Same merge-and-diff approach as Phase 6 — read existing, merge, present diff, write on approval.

### Project Isolation

Merge these into `.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Edit(~/*)",
      "Write(~/*)",
      "Edit(../*)",
      "Write(../*)",
      "Read(.env)",
      "Read(.env.*)",
      "Read(**/*.pem)",
      "Read(**/*credential*)",
      "Read(**/*secret*)"
    ]
  }
}
```

### Global Security Hardening

Offer to merge these into the user's `~/.claude/settings.json` (ask first — this is a global file):

```json
{
  "permissions": {
    "deny": [
      "Edit(~/Desktop/**)",
      "Edit(~/Documents/**)",
      "Write(~/Desktop/**)",
      "Write(~/Documents/**)"
    ]
  }
}
```

### Sandbox Configuration

```json
{
  "sandbox": {
    "enabled": true,
    "allowUnsandboxedCommands": false
  }
}
```

Explain to the user:
- **Sandbox mode** restricts Bash to the current directory (filesystem + network isolation). Reduces permission prompts by ~84% while increasing safety
- **Permission deny rules** block Edit/Write/Read tools from reaching secrets and external paths
- **Both layers together** give strong isolation
- For serious hardening, also consider network isolation via the sandbox proxy

### Destructive Git Operations

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

## Phase 8: Completion & Output

### Verification Policy

Distinguish between iteration and completion:

**During iteration**: run the smallest meaningful check — typecheck a single file, run the affected test. Fast feedback, keep moving.

**Before claiming DONE**: run the FULL verification chain. Every check must pass. If a check is genuinely unavailable (no test suite, no linter), report exactly:
- What you ran and what passed
- What you could not run and why
- What the user needs to verify manually

NEVER claim "done" with untested paths. NEVER skip verification because "it should work." NEVER say "tests pass" without showing the output.

### Output Format

```
## CLAUDE.md Forge Report

### Project: [name]
### Stack: [detected]
### Existing CLAUDE.md: [found/not found]

### Audit Score: [X/80] — Grade [A-F]
[Specific issues by category + placement analysis]

### Generated CLAUDE.md
[The complete file, sized appropriately for project complexity]

### Scoped Rules (if needed)
[Any .claude/rules/*.md files]

### Skills (if applicable)
[Any .claude/skills/<name>/SKILL.md files for heavy workflows]

### Settings & Hooks to Install
[Merged .claude/settings.json diff — hooks, permissions, sandbox config]
[Show exactly what will be added/changed in the settings file]

Say "write it" to apply ALL of the above — CLAUDE.md, rules, skills, settings, and hooks — in one shot.

### Next Steps
1. Review everything above — every line should feel necessary
2. Say "write it" to apply all files and settings
3. Run `/xforge score` periodically to check for bloat
4. After corrections: "update CLAUDE.md so you don't make that mistake again"
5. Use Plan Mode (Ctrl+G) for complex tasks — this separates planning from coding
6. Use `claude --worktree` for parallel work
```

## Problem → Solution Map

| Problem | Rule That Fixes It |
|---|---|
| Veers off plan | "Plan ONLY — no code until approved" |
| Skips requirements (does 3 of 5) | "Plans MUST account for EVERY requirement. Re-read request before claiming done" |
| Starts coding before reading full request | "Read the FULL request before responding" |
| Half-assed implementations / skeletons | Two-failure-modes preamble: skipping is the more common defect |
| Bloats code with unrequested additions | "Do EXACTLY what was asked. No more, no less" + anti-bloat rules |
| Bandaid fixes | "Fix root causes, not symptoms" |
| Invents new patterns, ignores existing | "Trace one similar feature e2e. Match EXACTLY — same structure, names, patterns" |
| Leaves TODOs and "implement later" stubs | "If you write it, finish it. Don't leave a skeleton and call it done" |
| Needs immediate refactoring | Forced verification gate |
| Scope creep/reduction | "Max 5 files per phase, verify between" |
| Context decay after 10+ messages | "Re-read files before editing" |
| Tests pass but code is wrong | "NEVER weaken a test. Strong assertions only" |
| Goes in circles on bugs | "2 failed attempts → stop, re-read, explain. Still stuck → /clear" |
| Modifies other projects | Project boundary + permission deny rules |
| CLAUDE.md gets ignored | Smart budget + placement analysis + route overflow to rules/skills/hooks |
| New code not wired | "Every function must have a CALLER" |
| Says "supports X" but X is broken | Anti-Silent-Failure: prove full path end-to-end |
| Pruning destroys critical rules | NEVER-PRUNE classification before any removal |
| Root file is kitchen sink | Placement framework: ROOT/RULE/SKILL/HOOK/LOCAL/PRUNE |

## References

- [Anthropic Best Practices](https://code.claude.com/docs/en/best-practices)
- [Anthropic Memory / CLAUDE.md](https://code.claude.com/docs/en/memory) — under 200 lines per file, `@import` max 5 hops, CLAUDE.local.md for personal notes
- [Anthropic Hooks](https://code.claude.com/docs/en/hooks) — 25 event types, command/http/prompt/agent handlers
- [Anthropic Settings](https://code.claude.com/docs/en/settings) — permission rules, sandbox config, scope precedence
- [Anthropic Skills](https://code.claude.com/docs/en/skills) — SKILL.md under 500 lines, frontmatter fields, dynamic context
- [Anthropic Sandboxing](https://www.anthropic.com/engineering/claude-code-sandboxing) — 84% fewer permission prompts, filesystem + network isolation
- [Cross-project issue #5773](https://github.com/anthropics/claude-code/issues/5773) — Edit/Write can reach outside working directory
