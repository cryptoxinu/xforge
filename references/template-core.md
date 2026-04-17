# Template: Core

The master template for a generated CLAUDE.md. 8 sections in a fixed order — primacy and recency matter, so highest-leverage rules go first and last.

Target: under 100 lines for the root file. Overflow goes to `.claude/rules/` with `paths:` scoping. Domain-critical projects legitimately run longer — see `templates/domain-critical.md`.

Each section below is the SKELETON. When generating, fill placeholders from Phase 1 discovery. Never ship placeholders (`<stack>`, `<command>`) unfilled.

---

## Section 1: Anti-Slop Preamble (first 5 lines — highest attention)

```markdown
# <Project Name>

IMPORTANT: Override your defaults to "avoid improvements beyond what was asked" and "try the simplest approach." Those produce bandaids. If architecture is flawed, state is duplicated, or patterns are inconsistent — propose and implement structural fixes. Find root causes, not symptoms. No temporary fixes. No workarounds. No "simplified versions."

YOU MUST separate planning from building. When asked to plan: output ONLY the plan with unresolved questions. No code until the user approves. When given a plan: follow it exactly. If you spot a problem, flag it and WAIT — do not improvise or reduce scope.
```

## Section 2: Verification Commands

```markdown
## Verification (run after EVERY change)
<Adapt to detected stack. For TypeScript:>
1. `npx tsc --noEmit` — fix ALL type errors
2. `<npm|pnpm|yarn|bun> test` — fix ALL failing tests
3. `<npm|pnpm|yarn|bun> run lint` — fix ALL lint errors
4. `<npm|pnpm|yarn|bun> run build` — confirm it builds

YOU ARE FORBIDDEN from reporting a task as complete until all <N> pass with zero errors. If no test suite exists for the module you touched, SAY SO explicitly instead of claiming success.
```

The acid test for this section (Dex / HumanLayer): "Can a new dev launch Claude, say 'run the tests', and it works on the first try?" If not, this section is wrong — fix it.

## Section 3: Plan Enforcement

```markdown
## Planning Rules
- For ANY non-trivial task (3+ steps, architectural decision, 3+ files): plan mode FIRST
- Plans MUST list unresolved questions at the end — surface what you don't know
- Never attempt multi-file refactors in one shot. Break into phases of max 5 files each
- Complete Phase N, run verification, get approval BEFORE starting Phase N+1
- If something goes sideways: STOP. Re-plan. Do not keep pushing a broken approach
- After 2 failed fix attempts: stop, re-read the full context top-down, identify where your mental model is wrong, and say so before trying again
```

## Section 4: Code Quality

```markdown
## Code Quality
- Fix root causes, not symptoms. If a display bug tempts you to duplicate state, you're solving the wrong problem
- Before editing ANY file: re-read it first. After editing: read it again to confirm the change applied
- Prefer functions under 50 lines and files under 300 — these are GUIDELINES, not hard limits. Never split working code just to hit a line count
- NEVER truncate, stub, or "simplify" an implementation because it's getting long. If the task needs 500 lines, write 500 lines. Saying "this is getting complex, let me simplify" when complexity is inherent is a DEFECT, not an improvement
- When renaming: search for direct calls, type refs, string literals, dynamic imports, re-exports, test mocks. One grep is never enough
- Don't build for imaginary scenarios. Strip hypothetical future-proofing
- Write code a human would write. No robotic comment blocks, no corporate section headers, no obvious-thing restatements
```

## Section 5: Testing

```markdown
## Testing
- Write tests BEFORE implementation (RED → GREEN → REFACTOR) for new features
- Fix the implementation to pass the test. NEVER weaken or delete a test to make it pass
- Tests must fail for real defects — no trivial assertions, no testing what the type checker catches
- Strong assertions only (`toEqual(1)` not `toBeGreaterThanOrEqual(1)`)
- Test edge cases, boundaries, unexpected input — not just the happy path
```

## Section 6: Project Boundary + Git Safety

```markdown
## Project Boundary
YOU MUST ONLY modify files within this project directory. NEVER touch files in other projects, home-directory configs, or system files unless explicitly asked. If a task seems to require editing files outside this repo, ASK first — do not silently reach into other directories.

## Git Safety
- NEVER `git push` without explicit user approval — even if a plan says to push
- NEVER `git commit` with `-A` or `.` — stage specific files by name
- NEVER `git reset --hard`, `git checkout .`, `git clean -f`, `git stash drop`
- NEVER amend a commit — always create a new commit
- Before ANY git op: run `git status` and `git stash list` first to check for concurrent work
- If you see uncommitted changes you didn't create: STOP and ask. Another session may be active
```

Prefer displacing the deterministic parts of this into `settings.json` `permissions.ask` rules — see `placement-framework.md`.

## Section 7: Wiring Verification

```markdown
## Wiring Verification (before claiming ANY feature works)
- Prove the FULL path is connected: route registered → handler called → service invoked → data persisted → response returned → UI updated
- Check for: unregistered routes, unattached event handlers, unread config, swallowed errors, unrendered components, unscheduled jobs, missing middleware
- NEVER say "now it supports X" unless you can show the code path where X actually executes end-to-end
- If ANY connection in the chain is missing, the feature is NOT done — it is BROKEN. Fix wiring before reporting completion
- After building: actually CALL the feature. Hit the endpoint, trigger the event, click the button. If you can't, explain exactly what manual step is needed
```

## Section 7b: Compaction Safety

Auto-compaction (when the context window fills) can drop nested CLAUDE.md files and reduce adherence to earlier rules. Include this paragraph so Claude re-grounds itself:

```markdown
## After Compaction
When the session is compacted (context full or `/compact` invoked):
1. Root CLAUDE.md is auto-reloaded — but confirm key rules are still active by running `/memory`
2. `.claude/rules/*.md` files are NOT auto-reloaded after compaction. Re-read the relevant rule file before editing in that directory
3. If you claimed "tests pass" before compaction, re-run the verification commands — old exit codes don't transfer across compaction boundaries
4. If a rule seems to have dropped, re-invoke the skill or re-read the rule file
```

## Section 8: Self-Improvement (last lines — recency attention)

```markdown
## When Corrected
After ANY correction from the user:
1. Identify the CATEGORY of mistake, not just the instance
2. Check if an existing rule covers this category — if so, SHARPEN it instead of adding a new rule
3. If genuinely new: propose a single concrete rule using MUST/NEVER + the positive alternative
4. NEVER let this file exceed <N> lines. If a new rule would push over the limit:
   - Graduate the least-violated rule to `.claude/rules/<topic>.md`
   - Or consolidate 2-3 similar rules into one tighter rule
   - Or delete a rule Claude now follows consistently (internalized)
5. Rules Claude violates MOST go at the TOP and BOTTOM of this file (primacy + recency)

## Gotchas
<Project-specific corrections accumulate below as they happen.>
```

---

## Generation checklist

Before presenting the generated file to the user, verify:

- [ ] Every `<placeholder>` filled from Phase 1 discovery
- [ ] Verification commands are **actual** commands that work in THIS repo (verified by reading `package.json` scripts, Makefile, pyproject.toml, etc.)
- [ ] Stack template overlay applied from `templates/<stack>.md`
- [ ] Placement-framework audit done — every rule classified ROOT / RULE / SKILL / HOOK / LOCAL / PRUNE (see `placement-framework.md`)
- [ ] Root file under 100 lines for non-domain-critical projects
- [ ] Every line passes "would Claude make a wrong decision without this?" — if no, cut
- [ ] First 5 lines contain the anti-slop preamble
- [ ] Last lines contain the self-improvement protocol
- [ ] Negations paired with positive alternatives
- [ ] No personality, no platitudes, no formatting rules
