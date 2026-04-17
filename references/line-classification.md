# Line Classification (NEVER-PRUNE)

Every line in an existing CLAUDE.md must be classified before any improvement or rewrite. This prevents xforge from destroying hard-won project knowledge.

## The 4 categories

### PROTECTED (never remove, never weaken, never consolidate)

These encode things Claude cannot infer from code and whose loss would cause incidents.

- Security invariants — "NEVER store plaintext PHI", "ALL gates deterministic", "Never log raw request bodies"
- Encryption / PII / PHI pipelines — tier architecture, anonymization order, canonical storage locations
- Medical / legal / compliance requirements — HIPAA, PCI-DSS, GDPR prose tied to specific code paths
- Data governance — table mappings, single-source-of-truth declarations
- Required function/module call chains — "All uploads MUST pass redaction_pipeline.run() before storage"
- Safety-critical "NEVER do X" rules with a known historical consequence
- Cross-platform parity requirements — iOS and Android must render identical consent flow
- Architecture decisions that prevent data loss — "Never drop migrations", "Never squash migrations below N"

Rule of thumb: if removing it would cause an incident, ask a lawyer, or break a cross-team contract — PROTECTED.

### MOVABLE (relocate to `.claude/rules/` with `paths:` scoping, but never delete)

These are real rules, just too domain-specific to earn a slot in the root CLAUDE.md's attention budget.

- Module-specific rules → `.claude/rules/<module>.md` with `paths:` frontmatter for the matching dir
- Background job / scheduler rules → `.claude/rules/scheduler.md`
- LLM / model routing rules → `.claude/rules/llm-routing.md`
- Test-specific conventions → `.claude/rules/testing.md`
- Frontend vs backend split → `.claude/rules/frontend.md`, `.claude/rules/backend.md`
- Pipeline-specific gotchas — e.g. PDF redaction, image processing, search indexing

`paths:` frontmatter only loads the rule when Claude is working with matching files (verified in code.claude.com/docs/en/memory). Rules without `paths:` load every session with root-CLAUDE.md priority — use that only for critical cross-cutting invariants (security, data governance).

### CONSOLIDATABLE (merge similar rules into one tighter rule)

Safe to combine without losing meaning.

- Multiple phrasings of the same idea ("be careful with X", "watch out for X", "X is dangerous")
- Overlapping rules that address the same risk from different angles
- Verbose explanations that compress without losing the load-bearing phrase
- Rules that cover a subset of a stronger, broader rule already present

Before consolidating: write the proposed merged version and confirm every original intent survives.

### PRUNABLE (safe to remove entirely)

- Generic advice Claude follows without the rule ("write readable code", "use meaningful names", "add comments when necessary")
- Information Claude can discover by reading code (file lists, directory structure, function signatures)
- Stale references — verify first that the file/function/command actually no longer exists
- Formatting rules that belong in linter config (.editorconfig, prettier, ruff, gofmt)
- Personality/role instructions ("Act as a senior engineer") — wastes attention, Claude already has strong system directives
- Code snippets embedded as rules — they go stale; use a file:line reference instead
- Directory listings — `ls` and `glob` exist
- Lines duplicated elsewhere in the same CLAUDE.md

## Process

1. Classify every line into one of the 4 categories. Output a table.
2. Run the settings-displacement audit (`settings-displacement.md`) — some MOVABLE lines are actually SETTINGS-DISPLACEABLE and should leave prose entirely.
3. For PROTECTED: never touch them. Preserve verbatim through any rewrite.
4. For MOVABLE: propose a `.claude/rules/<name>.md` with `paths:` frontmatter. Show the relocation diff.
5. For CONSOLIDATABLE: propose the merged version side-by-side with the originals.
6. For PRUNABLE: list with reason. Let the user veto per-line.
7. Before writing: diff original-total-lines vs proposed-total-lines across ALL files. Every PROTECTED + MOVABLE line must exist somewhere in the proposal.

## Edge cases

- **Ambiguous line** — when in doubt, classify PROTECTED. You can always re-prune later. You cannot undo a deleted lesson.
- **"Never do X" with no known reason** — ask before pruning. The reason may be a past incident not documented in the CLAUDE.md itself.
- **Contradicting rules** — flag both, ask the user to pick. Do not silently resolve.
- **Domain-critical project (medical, finance, security)** — bias toward PROTECTED classification. The cost of pruning a real rule dwarfs the cost of keeping a redundant one.
