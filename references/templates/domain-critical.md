# Template Overlay: Domain-Critical (medical, finance, security, legal)

## Clarifying Questions (ask BEFORE generating for domain-critical projects)

Domain-critical projects legitimately need rules Claude cannot infer from code alone. xforge MUST ask these four questions before generating a CLAUDE.md for any project that handles PHI, PCI/financial data, authentication/key material, legal documents, or safety-critical infrastructure.

Threshold: if Phase 1 discovery finds **3+ of** (custom build pipeline, domain-specific data handling, multiple deployment targets, compliance requirements, encryption/vault code, audit-log tables), ASK. Otherwise, infer from code.

The 4 questions, verbatim:

1. **"What are your protected invariants?"** — rules that must NEVER be weakened. Encryption schemes, AAD strings, compliance requirements (HIPAA §§, PCI-DSS 3.4, SOC 2 CC6.1, GDPR Art. 17), safety-critical constraints, data governance policies. These become PROTECTED classification and go into the root CLAUDE.md verbatim.

2. **"Are there non-obvious architectural decisions?"** — things Claude would get wrong by reading code alone. "We use two databases because X", "this module is intentionally duplicated for isolation", "never log the `raw_request_body` field — it's only there for legal replay".

3. **"What mistakes has Claude made repeatedly?"** — the user's pain points are the highest-leverage rules. These go at the TOP and BOTTOM of the file (primacy + recency attention). Ask for the last 3–5 specific corrections.

4. **"Any commands or paths that recently changed?"** — catches the most common staleness: renamed scripts, moved directories, new build steps. Cross-reference with the staleness audit (`staleness-audit.md`).

Only AFTER these answers: generate.

---

Apply this overlay IN ADDITION to the stack template when the project handles:
- Patient health information (PHI) / medical records
- Financial transactions, brokerage, payments, tax data
- Authentication, key material, secrets
- Legal documents, compliance evidence
- Critical infrastructure

These projects legitimately run 150+ lines in CLAUDE.md. Pruning aggressively here is dangerous — missing a rule can cause a reportable incident. Bias toward PROTECTED classification.

## Use `<important if>` tags for conditional rules

This is a community pattern from HumanLayer (see `important-if-pattern.md` for caveats — it's not an official Claude Code feature). The theory: conditional framing reduces Claude's tendency to treat sections as optional as the file grows.

```markdown
<important if="you are touching PHI, patient data, or the redaction pipeline">
NEVER log raw request bodies when they may contain PHI. Scrub via `src/phi/scrubber.py` BEFORE any log/print/telemetry call. This is audit-critical — redaction misses are reportable to OCR as a HIPAA breach.

ALL PDF uploads MUST pass `redaction_pipeline.run()` before any storage write. The pipeline is fail-closed — if OCR fails, the file is rejected, not passed through.
</important>

<important if="you are writing encryption, key management, or vault code">
AES-256-GCM with authenticated associated data (AAD). The AAD strings "relaxed.health_data" and "relaxed.memory" are LOAD-BEARING — changing them breaks all existing encrypted data. If you're rotating an AAD, you also need a migration path for existing ciphertexts.
</important>
```

## Hard-enforcement rules that belong in `settings.json` / hooks

CLAUDE.md prose is advisory. For domain-critical invariants, ALSO add deterministic enforcement:

1. **Block PHI in logs** — PreToolUse hook on Write that scans the written content for regex patterns (SSN, DOB, phone, known patient IDs) and blocks via `permissionDecision: "deny"`.
2. **Block writes to vault / key-material paths without explicit approval** — `permissions.ask` rules in `settings.json` for `Edit(src/vault/**)`, `Write(~/.<project>/vault/**)`, etc.
3. **Block `git push` without approval** — `permissions.ask` rule for `Bash(git push*)`.
4. **Audit-log every destructive op** — PostToolUse hook that appends to an audit log.

See `hooks-recipes.md` for the verified syntax.

## Cross-platform parity

Many domain-critical apps ship on multiple platforms (iOS, Android, web, CLI). Parity is PROTECTED — the same consent flow, the same redaction, the same safety banners. Document which are contractually required identical.

```markdown
## Cross-Platform Parity (PROTECTED)
- iOS and Android consent screens MUST render identical text from `i18n/consent/*.json`
- Web and native use the SAME redaction pipeline via shared `redact_v2` binding
- Never add a platform-specific safety override — use the shared contract or escalate to the legal review
```

## Data tiering

```markdown
## Data Tiers (PROTECTED — changing these breaks audits)
- Tier 1 (public): marketing, docs, non-identifying metadata
- Tier 2 (sensitive): user-supplied config, preferences
- Tier 3 (PHI/PII): health data, names, identifiers — encrypted at rest with key rotation
- Tier 4 (security-critical): keys, tokens, audit log — separate vault, HSM if available

Code referencing Tier 3 or Tier 4 data MUST go through the tier API. Direct file reads/writes are a DEFECT.
```

## Never-delete rules

```markdown
## Never Delete (PROTECTED)
- NEVER `rm` or `git rm` medical records, financial transactions, or audit logs — archive instead
- NEVER squash migrations below the production-deployed point — they may contain irreversible schema history
- NEVER drop database tables in a migration without an explicit archive step documented in the migration
- "Unreferenced code" ≠ dead code when it's part of an in-progress feature. Ask before deleting
```

## Regulatory anchors

For each regulation the project is subject to, cite the specific requirement and where in code it's enforced. Example:

```markdown
## Compliance Anchors
- HIPAA 45 CFR §164.312(a)(2)(iv) Encryption: src/crypto/vault.py
- HIPAA §164.312(b) Audit Controls: src/audit/log.py + Stop hook
- PCI-DSS 3.4 (card data not stored): enforced by hook `.claude/hooks/block-pan.sh`
- SOC 2 CC6.1 (logical access): auth middleware at src/auth/middleware.py
- GDPR Art. 17 (erasure): src/privacy/erasure.py
```

## Partial-migration detection is CRITICAL here

Mixed framework states in a domain-critical project are incidents waiting to happen. Flag in `score` mode and include in the Top 3 Issues if detected.

## Size allowance

Default root CLAUDE.md target: **up to 200 lines** (official ceiling) for domain-critical projects. Offload everything else to `.claude/rules/` with `paths:` scoping. Example structure:

```
.claude/rules/
├── security.md          (paths: ["src/security/**", "src/ingest/**"])
├── data-governance.md   (paths: ["src/data/**", "src/db/**"])
├── pdf-pipeline.md      (paths: ["src/pdf/**"])
├── llm-routing.md       (paths: ["src/llm/**"])
└── compliance.md        (no paths — loads every session, cross-cutting)
```

Rules WITHOUT `paths:` frontmatter load unconditionally at root priority. Use that for cross-cutting compliance and security rules. Scope everything else so attention is focused only when Claude is in the relevant directory.
