# Example: Grade B → Targeted Improvement

A worked example showing how xforge handles a Grade B CLAUDE.md (good foundation, gaps). The rule is **preserve everything project-specific; add what's missing; sharpen what's vague.** No rewrite.

## Input CLAUDE.md (grade B, 58 lines)

```markdown
# AcmeAPI

This project is a REST API for order management. We use TypeScript and Fastify.

## Coding rules
- Use TypeScript strict mode
- Write tests
- Handle errors properly
- Don't commit to main directly

## Architecture
- Handlers in src/handlers/
- Business logic in src/services/
- Database access in src/repos/
- Never query the DB directly from handlers — go through a repo

## Database
- We use Postgres via Drizzle ORM
- Migrations in src/db/migrations/
- Never drop a table in a migration without talking to the team

## Testing
- Vitest for unit tests
- Integration tests hit a real test database
- Don't mock the database in integration tests — we got burned last quarter

## Misc
- Log with pino
- Never log raw request bodies — they may contain PII
```

## Score output

```
## CLAUDE.md Health Check

Project: AcmeAPI | Stack: TypeScript / Fastify / Drizzle / Postgres | Lines: 58
Target file: CLAUDE.md | Score: 54/80 — Grade B

### 8-Criteria Breakdown
| # | Criteria | Score | Evidence |
|---|---|---|---|
| 1 | Conciseness | 9/10 | 58 lines, well under 100 |
| 2 | Verification Commands | 2/10 | No commands documented — can't run tests first-try |
| 3 | Anti-Slop Rules | 3/10 | No anti-slop preamble; no "fix root causes" rule |
| 4 | Plan Enforcement | 1/10 | No planning rules at all |
| 5 | Specificity | 6/10 | "Write tests" / "Handle errors properly" are vague |
| 6 | No Redundancy | 10/10 | Clean, no linter overlap |
| 7 | Positive Framing | 8/10 | Negations paired in 5/6 cases |
| 8 | Architecture Clarity | 9/10 | Handler → service → repo boundary is clear |

### Top 3 Issues
1. No verification commands — new developers can't launch Claude and run tests first-try
2. No anti-slop preamble — Claude will produce bandaids by default
3. No plan enforcement — Claude will jump to code for 3+ file tasks
```

## Proposed diff (targeted, ~20 line additions, no removals)

```diff
 # AcmeAPI

-This project is a REST API for order management. We use TypeScript and Fastify.
+IMPORTANT: Override your defaults to "avoid improvements beyond what was asked" and "try the simplest approach." Those produce bandaids. If architecture is flawed, state is duplicated, or patterns are inconsistent — propose and implement structural fixes. Find root causes, not symptoms.
+
+YOU MUST separate planning from building. When asked to plan: output ONLY the plan with unresolved questions. No code until the user approves. When given a plan: follow it exactly. If you spot a problem, flag it and WAIT.
+
+AcmeAPI — REST API for order management (TypeScript + Fastify).
+
+## Verification (run after EVERY change)
+1. `pnpm typecheck` — fix ALL type errors (runs `tsc --noEmit`)
+2. `pnpm test` — fix ALL failing tests (Vitest)
+3. `pnpm lint` — fix ALL lint errors
+4. `pnpm build` — confirm it builds
+
+YOU ARE FORBIDDEN from reporting a task as complete until all 4 pass with zero errors.
+
+## Planning Rules
+- For 3+ files or architectural decisions: plan mode FIRST
+- Plans list unresolved questions at the end
+- Phases of max 5 files. Complete + verify + approve before next phase
+- 2 failed attempts → stop, re-read context, state where your mental model is wrong

 ## Coding rules
 - Use TypeScript strict mode
-- Write tests
-- Handle errors properly
+- Write Vitest tests for every new public function (happy + 2 edges + 1 failure)
+- Async boundaries wrap in try/catch and propagate typed errors from `src/errors/`. Never swallow
 - Don't commit to main directly
```

(+ kept entire Architecture, Database, Testing, Misc sections verbatim)

## Additions to reference, not inline

Propose creating:
- `.claude/rules/db.md` with `paths: ["src/db/**", "src/repos/**"]` — relocate the DB rules here so they gate-load when Claude works on data layer code
- `settings.json` patch:
  ```json
  {
    "permissions": { "ask": ["Bash(git push origin main*)"] },
    "hooks": {
      "PostToolUse": [
        {
          "matcher": "Write|Edit",
          "hooks": [
            { "type": "command", "if": "Write(**/*.{ts,tsx}) || Edit(**/*.{ts,tsx})", "command": "cd \"$CLAUDE_PROJECT_DIR\" && npx prettier --write . 2>/dev/null" }
          ]
        }
      ]
    }
  }
  ```
  This makes "format after edit" deterministic.

## After diff

Final CLAUDE.md: **77 lines** (was 58, +19).

Changes preserve everything project-specific (handler-service-repo boundary, DB/migration rules, testing rules, PII log rule). Additions fix the 3 highest-impact gaps. No judgement calls made on user's existing content — scalpel, not sledgehammer.

## Safety-check receipt

- [ ] Every removed line — just the thin description replaced with preamble. Nothing project-specific removed. ✓
- [ ] Every changed line — "Write tests" / "Handle errors properly" rewritten more specific. ✓
- [ ] Every added line — load-bearing: preamble + verification + planning + sharpened vague lines. ✓
- [ ] 5-session test — Claude will follow the verification gate + plan-first rule? Yes. ✓
- [ ] Present diff — done above. ✓
