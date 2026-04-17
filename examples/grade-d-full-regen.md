# Example: Grade D → Full Regeneration (with knowledge preservation)

Grade D means the existing CLAUDE.md actively hurts. The rule is **regenerate from scratch, but mine the old file for domain-specific knowledge and carry it forward.** Don't just throw it away.

## Input CLAUDE.md (grade D, 42 lines)

```markdown
# My App

You are a senior software engineer. Be helpful and write clean code.

## Rules
- Write meaningful variable names
- Use proper indentation (we use 2 spaces)
- Use tabs for indentation
- Always add comments
- Don't add too many comments
- Test your code
- Use TypeScript
- Use ES modules
- Format code nicely
- Follow best practices
- Be DRY
- Be careful with the database
- PHI data is important, be careful

## About this project
This is a healthcare app. It handles patient data. Be extra careful.

## Commands
Run `npm install` to install.
The test command is `jest`.
```

Tell-tale signs this is Grade D:
- Personality instruction ("You are a senior software engineer")
- Generic platitudes ("clean code", "follow best practices")
- Contradicting rules (2 spaces AND tabs for indentation)
- Negation with contradictory guidance ("always add comments" + "don't add too many")
- Vague verbs throughout ("properly", "nicely", "be careful")
- One PROTECTED line buried in vague prose ("PHI data is important, be careful" — this is domain-critical but not actionable)
- No verification gate, no plan enforcement, no anti-slop preamble

## Score output

```
## CLAUDE.md Health Check

Project: My App | Stack: TypeScript / Jest | Lines: 42 | Grade D (27/80)

### What's PROTECTED to carry forward
Line 17: "This is a healthcare app. It handles patient data. Be extra careful." 
  → Healthcare domain. Must drive domain-critical overlay.
  → Sharpen to specific rules about PHI scrubbing in logs, encryption-at-rest, audit log.

### What's PRUNABLE
Lines 3, 5-11, 13-15, 20-21: generic platitudes, contradictions, personality — REMOVE

### What's MOVABLE
Lines 18-21: command list → move to Verification section with actual tested commands
```

## Proposed regeneration (domain-critical overlay applied)

```markdown
# My App

IMPORTANT: Override your defaults to "avoid improvements beyond what was asked" and "try the simplest approach." Those produce bandaids. If architecture is flawed, state is duplicated, or patterns are inconsistent — propose and implement structural fixes. Find root causes, not symptoms. No temporary fixes.

YOU MUST separate planning from building. When asked to plan: output ONLY the plan with unresolved questions. No code until the user approves. When given a plan: follow it exactly. If you spot a problem, flag it and WAIT.

My App — healthcare platform handling PHI. Domain-critical: tighten before you relax.

## Verification (run after EVERY change)
1. `npm run typecheck` — `tsc --noEmit`, fix ALL type errors
2. `npm test` — Jest, fix ALL failing tests
3. `npm run lint` — fix ALL lint errors
4. `npm run build` — confirm it builds

YOU ARE FORBIDDEN from reporting a task complete until all 4 pass with zero errors.

## Planning Rules
- 3+ files or architectural decisions → plan mode FIRST
- Plans list unresolved questions at the end
- Phases of max 5 files each. Complete + verify + approve before the next phase
- 2 failed attempts → stop, re-read context, explain where your mental model is wrong

## PHI Handling (PROTECTED)
<important if="you are writing logging, telemetry, metrics, or error reporting">
NEVER log raw request bodies when they may contain PHI.
ALWAYS scrub via `src/phi/scrub.ts::scrubPHI()` BEFORE any log, print, metric, or trace call.
Redaction misses are reportable HIPAA breaches.
</important>

<important if="you are touching patient records, encounters, or exports">
All patient data access goes through `src/patient/repo.ts`. Never query the patient tables directly from route handlers.
All exports emit an `audit.log` row in the same transaction — never after.
</important>

## Code Quality
- Fix root causes, not symptoms. If a display bug tempts you to duplicate state, you're solving the wrong problem
- Before editing ANY file: re-read it first. After editing: read it again
- NEVER truncate, stub, or "simplify" an implementation. If the task needs 500 lines, write 500 lines
- Write code a human would write. No robotic comment blocks, no corporate section headers

## Testing
- Write tests BEFORE implementation (RED → GREEN → REFACTOR) for new features
- Fix the implementation to pass the test. NEVER weaken a test to make it pass
- For PHI handling: tests must cover the scrub pipeline end-to-end

## Project Boundary + Git Safety
- ONLY modify files within this project
- NEVER `git push`, `git reset --hard`, or `git commit -A` without explicit approval
- Before ANY git op: `git status` + `git stash list` to check for concurrent work

## When Corrected
After ANY correction: identify the CATEGORY of mistake, check if an existing rule covers it, sharpen that rule. If genuinely new, add one concrete MUST/NEVER + positive alternative. Never let this file exceed 100 lines — graduate to `.claude/rules/` or consolidate first.

## References
- For detailed PHI handling: `.claude/rules/phi.md` (loads in src/patient/, src/export/, src/phi/)
- For Jest testing conventions: `.claude/rules/testing.md`

## Gotchas
<Project-specific corrections accumulate here.>
```

## Also proposed: `.claude/rules/phi.md`

```markdown
---
paths:
  - "src/patient/**"
  - "src/export/**"
  - "src/phi/**"
  - "src/ehr/**"
---

# PHI Handling — Expanded Rules

## Classification
- Tier 3 = PHI (names, DOBs, MRNs, diagnoses, notes, imaging)
- Tier 4 = security-critical (encryption keys, session tokens, audit-log integrity keys)

## Rules
- All PHI-writing code paths go through `src/phi/writer.ts` which applies encryption + audit
- Exports: `audit.logExport(userId, recordIds)` in same transaction as the export
- Never cache PHI outside `RedisPHI` (which has TTL + encryption) — never in generic caches
- On OCR/document ingestion: if `redactionPipeline.run()` returns error, the file is REJECTED, never stored

## Hooks to add (propose to user)
- PreToolUse Write|Edit with regex scan for SSN/MRN patterns → deny with "scrub first"
- PostToolUse Bash where command matches `git commit *` → run `grep -r 'patient_ssn\|dob_str' src/` to catch leaked patterns
```

## Also proposed: `settings.json` patch

```json
{
  "attribution": { "commit": "", "pr": "" },
  "permissions": {
    "ask": [
      "Bash(git push*)",
      "Bash(git reset --hard*)",
      "Bash(git commit -A*)"
    ],
    "deny": [
      "Edit(~/Desktop/**)",
      "Write(~/Desktop/**)"
    ]
  },
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

## Safety-check receipt

- PROTECTED line preserved: "PHI/healthcare" (line 17 original) → now drives domain-critical overlay, not buried in vague prose ✓
- Pruned ~30 lines of generic/personality/contradictory content ✓
- Added verification gate, planning rules, anti-slop preamble ✓
- Displaced attribution + git safety to settings.json (deterministic) ✓
- Relocated PHI detail to path-scoped rule (loads on demand in patient/export code) ✓
- Net: 42 → 62 lines in root + 14 lines in `.claude/rules/phi.md` = 76 total, but with dramatically higher per-line leverage ✓

## After diff

Root CLAUDE.md: **62 lines** (was 42). More useful, more specific, ~0 platitudes.
Plus: `.claude/rules/phi.md` for domain-critical detail (loads on demand)
Plus: `settings.json` patch for deterministic enforcement
