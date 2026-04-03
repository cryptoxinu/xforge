# xforge

**Forge battle-tested CLAUDE.md files that actually get followed.**

Stop fighting your AI assistant. `xforge` audits, scores, and generates CLAUDE.md files built from research across 50+ production setups, Boris Cherny's team practices, ETH Zurich's instruction-budget research, and hard-won community anti-slop rules.

## The Problem

Your CLAUDE.md is either:
- **Too long** and Claude ignores it (>150 lines = uniform instruction dropout)
- **Too generic** ("write clean code") and adds zero value
- **Missing the rules that matter** — so Claude veers off plan, ships bandaids, half-asses implementations, and leaves you refactoring

## What xforge Does

| Command | What It Does |
|---|---|
| `/xforge` | Audit existing CLAUDE.md + generate improved version |
| `/xforge new` | Generate fresh CLAUDE.md for current project |
| `/xforge audit` | Score-only mode (0-80 scale, A-F grade) |
| `/xforge global` | Improve your `~/.claude/CLAUDE.md` |

### 11-Phase Pipeline

1. **Project Discovery** — auto-detects stack, build/test/lint commands, existing rules
2. **Audit & Score** — grades existing CLAUDE.md against 8 criteria
3. **Generate/Rewrite** — creates a sub-80-line CLAUDE.md with battle-tested rules
4. **Scoped Rules** — overflows domain rules to `.claude/rules/` with path globs
5. **Hooks** — recommends deterministic enforcement (100% compliance)
6. **Project Isolation** — prevents cross-project file contamination
7. **Multi-Terminal Safety** — prevents session commit/push clobbers
8. **Dead Code Management** — distinguishes WIP from dead code
9. **Feature-Dev Rigor** — forces codebase exploration before writing
10. **Self-Improving + Lean** — 80-line budget with auto-consolidation
11. **Settings.json** — concrete permission/hook configurations

## Install

### One-liner (recommended)

```bash
mkdir -p ~/.claude/skills/xforge && curl -fsSL https://raw.githubusercontent.com/cryptoxinu/xforge/main/SKILL.md -o ~/.claude/skills/xforge/SKILL.md
```

### Manual

```bash
git clone https://github.com/cryptoxinu/xforge.git
cp xforge/SKILL.md ~/.claude/skills/xforge/SKILL.md
```

Then run `/xforge` in any Claude Code session.

## The Science Behind It

### The 80-Line Budget

Claude Code's system prompt consumes ~50 of the ~150-200 instruction slots frontier models reliably follow. Your CLAUDE.md gets ~100-150 slots. Research shows:

- **50 lines** = ~95% compliance per rule
- **80 lines** = ~85% compliance per rule
- **150+ lines** = ~60% compliance, dropping uniformly (not selectively)

A 50-line file at 95% beats a 200-line file at 60%. Every time.

### Rules That Actually Work

Every rule in xforge-generated files was validated across real production codebases:

| Problem | Rule |
|---|---|
| Veers off plan | Separate plan from build. No code until approved |
| Bandaid fixes | "Fix root causes, not symptoms" + forced verification |
| Half-assed work | Senior Dev Override — bypasses "simplest approach" default |
| Needs refactoring | Verification gate — FORBIDDEN from saying "done" without proof |
| Modifies other projects | Project boundary rule + permission deny settings |
| Multi-terminal clobbers | Git safety rules + worktree isolation |
| Deletes good WIP code | "Unreferenced != dead. Ask if recent" |
| CLAUDE.md gets ignored | 80-line budget + monthly audit + rule graduation |
| Doesn't match codebase | "Trace one similar feature e2e before building" |

### Hooks > Rules

CLAUDE.md rules are advisory (~80% compliance). Hooks are deterministic (100%). xforge recommends both:

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "npm test 2>&1 | tail -5; [ $? -ne 0 ] && echo '{\"decision\":\"block\",\"reason\":\"Tests failing.\"}'"
      }]
    }]
  }
}
```

## Research Sources

- [Anthropic Official Best Practices](https://code.claude.com/docs/en/best-practices)
- [Boris Cherny's Claude Code Tips](https://howborisusesclaudecode.com/)
- [ETH Zurich — Context File Impact on Agent Performance](https://github.com/reizam/claude-md-templates)
- [HumanLayer — Writing a Good CLAUDE.md](https://humanlayer.dev)
- [iamfakeguru/claude-md](https://github.com/iamfakeguru/claude-md) — highest-rated anti-slop rules
- [Sabrina Ramonov's ai-coding-rules](https://github.com/SabrinaRamonov/ai-coding-rules)
- [Community Best Practices](https://github.com/shanraisshan/claude-code-best-practice)

## License

MIT

## Author

[@cryptoxinu](https://github.com/cryptoxinu)
