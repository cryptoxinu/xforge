# Xforge Gotchas

Failure log. Append an entry every time xforge does something the user had to correct. Format is fixed — what happened, why, and what rule prevents it next time. Keep entries concrete and short.

The first time this file fills to 50+ entries, promote the most common failure categories into hardened rules inside `SKILL.md` itself.

## Entry template

```
### YYYY-MM-DD — <one-line what went wrong>
- **What I did**: <action xforge took>
- **What went wrong**: <user's correction, observed problem>
- **Why I did it**: <mental model that was wrong>
- **Rule for next time**: <concrete rule — MUST/NEVER + positive alternative>
- **Test for the rule**: <how to verify it fires correctly>
```

## Entries

<!-- Append chronologically below. Oldest stays near the top so patterns emerge. -->

### (none yet — this file grows with use)

---

## Common failure categories to watch for

These are predicted failure modes from reviewing the current xforge design. If any happen, escalate to a SKILL.md rule:

- **Pruning a PROTECTED rule** because it "looked generic" — missed that it encoded a historical incident
- **Displacing a rule to settings.json that the user didn't want automated** — moved prose to a hook the user didn't want running
- **Generating template commands that don't exist in the project** — invented `npm test` when the project uses `pnpm test`
- **Flagging a partial migration that was intentional** — dual framework during a documented transition period
- **Removing the "why" when consolidating rules** — consolidated "NEVER X because of incident Y" into just "NEVER X"
- **Writing `paths:` globs that don't match the real directory layout** — e.g. `src/auth/**` when the actual dir is `src/features/auth/**`
- **Applying the domain-critical overlay too aggressively** to a non-domain-critical project — made it feel bureaucratic
- **Being too aggressive in a `score` run** and writing something — score mode is READ-ONLY by contract

## Escalation rule

If the same failure category appears 3+ times in this file, STOP and escalate it:
- If it's a rule violation → promote to SKILL.md as a hard rule
- If it's a knowledge gap → add to the relevant reference file
- If it's an xforge design flaw → open a design-change note here and hold off that pattern until fixed
