---
description: "Run Xinu's ClaudeMD Fix — generate a fresh CLAUDE.md from scratch for the current project."
---

Invoke the `xforge` skill with argument "new".

Use this when the project has NO existing CLAUDE.md or the existing one is worth scrapping entirely and replacing. For existing files at grade C or better, prefer the default `/xforge` command (targeted improvement) instead.

Follow the skill's dispatch logic for "new":

1. Load `~/.claude/skills/xforge/SKILL.md`
2. If an existing CLAUDE.md is present, tar-backup it first (timestamped). Checkpointing covers Claude-edited files, but we want a rollback path for the bulk operation
3. Discover (language, package manager, scripts, frameworks, partial migrations, domain type)
4. Load `references/template-core.md` and the relevant `references/templates/<stack>.md`. If the project is medical/finance/security/legal, ALSO apply `references/templates/domain-critical.md`
5. Generate the 8 mandatory sections, filled with commands and patterns verified against the actual project (never invent `npm test` — read `package.json` scripts)
6. Propose `.claude/rules/` files for any domain-specific overflow (see `references/migration-playbook.md`)
7. Propose a `settings.json` patch displacing deterministic rules (see `references/settings-displacement.md`)
8. Propose hook recipes from `references/hooks-recipes.md` with verified syntax
9. Run the Do-No-Harm safety check — confirm every line is load-bearing, every command actually works, no platitudes, no invented tooling
10. Present a unified diff (empty → proposed) with WHY annotations, THEN wait for user approval before writing

Target: ≤100 lines for non-domain-critical, up to 200 for domain-critical. Overflow to `.claude/rules/` with `paths:` scoping.
