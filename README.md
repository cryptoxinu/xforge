# xforge

**Xinu's ClaudeMD Fix — forge battle-tested CLAUDE.md files that actually get followed.**

Stop fighting your AI assistant. `xforge` audits, scores, and generates CLAUDE.md files built from research across 50+ production setups, Boris Cherny's team practices, ETH Zurich's instruction-budget research, and hard-won community anti-slop rules.

## The Problem

Your CLAUDE.md is either:
- **Too long** and Claude ignores it (>150 lines = uniform instruction dropout)
- **Too generic** ("write clean code") and adds zero value
- **Missing the rules that matter** — so Claude veers off plan, ships bandaids, half-asses implementations, builds features that silently fail, and leaves you refactoring

## Commands

| Command | Changes Files? | What It Does |
|---|---|---|
| `/xforge score` | No | Quick health check — grade (A-F), top 3 issues, what to run next |
| `/xforge audit` | No | Detailed 8-criteria breakdown with per-category scores |
| `/xforge analyze` | No | Deep line-by-line classification: LOAD-BEARING / VAGUE / GENERIC / PROTECTED |
| `/xforge` | Yes (backs up first) | Full pipeline — backup, audit, grade-based improve/generate, present diff |
| `/xforge new` | Yes (backs up first) | Generate fresh CLAUDE.md from scratch for current project |
| `/xforge improve` | Yes (backs up first) | Improve your `~/.claude/CLAUDE.md` (personal defaults across all projects) |

## Safety Guarantees

- **Mandatory backup** before any change (timestamped, always restorable)
- **Do No Harm** — compares before/after, presents diff, keeps rules if unsure
- **Grade-based routing** — Grade A/B files get a scalpel, not a sledgehammer
- **NEVER-PRUNE classification** — security, data governance, medical, legal rules are PROTECTED and never removed
- **Soft code size guidelines** — prefers short but NEVER truncates complex implementations to hit a number

## What It Generates

Every xforge-generated CLAUDE.md includes 8 mandatory sections:

1. **Anti-Slop Preamble** — overrides Claude's "simplest approach" default
2. **Verification Commands** — stack-specific build/test/lint chain, FORBIDDEN from skipping
3. **Plan Enforcement** — separate plan from build, phased execution, 2-attempt escalation
4. **Code Quality** — root causes not symptoms, re-read before edit, soft size guidelines
5. **Testing** — TDD, never weaken tests, strong assertions
6. **Project Boundary + Git Safety** — no cross-project edits, no accidental pushes
7. **Anti-Silent-Failure** — 9-item checklist proving features are wired end-to-end
8. **Self-Improvement** — corrections compound into better rules over time

## What It Solves

| Problem | How xforge Fixes It |
|---|---|
| Veers off plan | Separate plan from build — no code until approved |
| Bandaid fixes | "Fix root causes, not symptoms" + forced verification gate |
| Half-assed work | Senior Dev Override — bypasses "simplest approach" default |
| Features silently fail | Anti-Silent-Failure: prove full path is connected end-to-end |
| Needs immediate refactoring | Verification gate — FORBIDDEN from saying "done" without proof |
| Modifies other projects | Project boundary rule + sandbox + permission deny settings |
| Multi-terminal clobbers | Git safety rules + worktree isolation + push confirmation hook |
| Over-simplifies complex code | Soft limits — "if task needs 500 lines, write 500 lines" |
| Deletes good WIP code | "Unreferenced != dead. Ask if recent" |
| CLAUDE.md gets ignored | Smart budget + monthly audit + graduated rules to .claude/rules/ |
| Pruning destroys critical rules | NEVER-PRUNE: 4-tier classification before any removal |
| Doesn't match codebase | "Trace one similar feature e2e before building" |

## Install

### One-liner

```bash
mkdir -p ~/.claude/skills/xforge && curl -fsSL https://raw.githubusercontent.com/cryptoxinu/xforge/main/SKILL.md -o ~/.claude/skills/xforge/SKILL.md
```

### Manual

```bash
git clone https://github.com/cryptoxinu/xforge.git
cp xforge/SKILL.md ~/.claude/skills/xforge/SKILL.md
```

Then run `/xforge score` in any Claude Code session to see where you stand.

## The Science

Claude Code's system prompt consumes ~50 of the ~150-200 instruction slots frontier models reliably follow. Your CLAUDE.md gets the remaining ~100-150. Research shows:

- **50 lines** = ~95% compliance per rule
- **80 lines** = ~85% compliance per rule
- **150+ lines** = ~60% compliance, dropping **uniformly** (not selectively)

For simple projects, xforge targets ~80 lines. For complex domain projects (medical, financial, security), it uses `.claude/rules/` with path scoping so domain rules load only when relevant — keeping total instruction load manageable while preserving every critical rule.

CLAUDE.md rules are advisory (~80% compliance). Hooks are deterministic (100%). xforge recommends both.

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
