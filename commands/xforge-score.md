---
description: "Run Xinu's ClaudeMD Fix — read-only health check. Grade, 8-criteria breakdown, line-by-line classification. Changes NOTHING."
---

Invoke the `xforge` skill with argument "score".

This is the READ-ONLY audit mode. Follow these rules exactly:

1. Load `~/.claude/skills/xforge/SKILL.md`
2. Load `~/.claude/skills/xforge/references/grading-rubric.md`, `line-classification.md`, `anti-patterns.md`, `acid-tests.md`, `settings-displacement.md`
3. Skip ANY backup phase — score mode never writes files
4. Run: Discover → Audit (8 criteria) → Classify every line → Settings-displacement audit → Acid tests → Partial-migration scan
5. Output the full score report in the exact format from `grading-rubric.md` (CLAUDE.md Health Check)
6. DO NOT create, edit, or write ANY files under any circumstances. If you feel tempted to write during this mode, STOP — score mode is read-only by contract

If no project CLAUDE.md exists, target `~/.claude/CLAUDE.md`. Announce which file you are scoring at the top of the report.

End the report with: "Run `/xforge` to auto-fix (diff-gated, safety-checked)."
