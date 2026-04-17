# Settings Displacement Audit

**Core insight** (davila7): don't put rules in CLAUDE.md when the harness can enforce them deterministically via `settings.json`. Prose is advisory and decays with file length; settings are 100% enforced by the harness.

Every CLAUDE.md rule must survive this test: **"Can this rule be enforced by the harness, a hook, or a linter?"** If yes, displace it. Keep CLAUDE.md for behavioral guidance only.

## What to displace to `settings.json`

### Attribution rules

**In CLAUDE.md (bad):**
```markdown
- NEVER add "Co-Authored-By: Claude" to commit messages
- NEVER add the "🤖 Generated with Claude Code" line
```

**In `settings.json` (good — 100% enforced):**
```json
{
  "attribution": {
    "commit": "",
    "pr": ""
  }
}
```

Empty strings hide attribution entirely. This takes precedence over the deprecated `includeCoAuthoredBy` field. Verified in code.claude.com/docs/en/settings.

### Git safety rules

**In CLAUDE.md (advisory):**
```markdown
- NEVER run `git push` without approval
- NEVER run `git reset --hard`
- NEVER run `git commit -A`
```

**In `settings.json` (enforced):**
```json
{
  "permissions": {
    "ask": [
      "Bash(git push*)",
      "Bash(git reset --hard*)",
      "Bash(git checkout -- *)",
      "Bash(git clean -f*)",
      "Bash(git stash drop*)",
      "Bash(git commit -A*)",
      "Bash(git commit -a*)",
      "Bash(git commit . *)"
    ]
  }
}
```

The `ask` list prompts the user before executing — Claude cannot bypass it. Keep a one-line reminder in CLAUDE.md ("Git ops prompt before destructive actions — see settings.json") so Claude understands why the prompts appear.

### File-boundary rules

**In CLAUDE.md (advisory):**
```markdown
- YOU MUST ONLY modify files within this project. NEVER touch files in other projects or ~/
```

**In `settings.json` (enforced):**
```json
{
  "permissions": {
    "deny": [
      "Edit(~/Desktop/**)",
      "Edit(~/Documents/**)",
      "Write(~/Desktop/**)",
      "Write(~/Documents/**)",
      "Edit(/etc/**)",
      "Write(/etc/**)"
    ]
  }
}
```

`Edit(...)` and `Write(...)` rules control Claude's file tools. `Bash` permission rules control shell commands. Both apply.

### Sandbox (strong boundary)

If you want the project to run all Bash commands in an isolated sandbox:
```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "failIfUnavailable": false,
    "excludedCommands": ["docker *"],
    "filesystem": {
      "allowWrite": [".", "/tmp"],
      "denyWrite": ["/etc", "/usr/local"]
    }
  }
}
```

Sandbox isolates subprocess commands from the filesystem/network at OS level — stronger than `permissions.deny`. Turn on `autoAllowBashIfSandboxed` and Claude stops asking for each `ls`/`cat`/`grep`. Verified schema from code.claude.com/docs/en/settings.

Set `"allowUnsandboxedCommands": false` in managed enterprise settings to prevent the `dangerouslyDisableSandbox` escape hatch.

## What to displace to hooks

### Auto-format on write

**In CLAUDE.md (bad):**
```markdown
- Always run `prettier --write` after editing .ts/.tsx files
- Always run `ruff format` after editing .py files
```

**In `settings.json` (PostToolUse hook — 100% runs):**
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "if": "Write(**/*.py) || Edit(**/*.py)",
            "command": "ruff format \"$CLAUDE_PROJECT_DIR\" 2>/dev/null; ruff check --fix \"$CLAUDE_PROJECT_DIR\" 2>/dev/null"
          },
          {
            "type": "command",
            "if": "Write(**/*.{ts,tsx,js,jsx}) || Edit(**/*.{ts,tsx,js,jsx})",
            "command": "cd \"$CLAUDE_PROJECT_DIR\" && npx prettier --write . 2>/dev/null"
          }
        ]
      }
    ]
  }
}
```

Note: `matcher` is a string (tool name, pipe-separated for alternatives). File-glob targeting lives in the `if` field. Verified from code.claude.com/docs/en/hooks.

### Verification gate

**In CLAUDE.md (advisory):**
```markdown
- NEVER claim a task done until tests pass
```

**In `settings.json` (Stop hook blocks session completion):**
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$CLAUDE_PROJECT_DIR\" && <test-command> 2>&1 | tail -5; if [ ${PIPESTATUS[0]} -ne 0 ]; then jq -n '{decision:\"block\", reason:\"Tests are failing. Fix before completing.\"}'; fi"
          }
        ]
      }
    ]
  }
}
```

See `hooks-recipes.md` for the full verified syntax with exit codes.

### Log all permission requests

To review what Claude asks for:
```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -c . >> \"$CLAUDE_PROJECT_DIR/.claude/permission-log.jsonl\""
          }
        ]
      }
    ]
  }
}
```

## What to displace to linter config

- Code style (indent, quotes, semicolons, line length) → `.editorconfig`, `.prettierrc`, `ruff.toml`, `rustfmt.toml`, `gofmt`
- Import ordering → `ruff` / `biome` / `import-sort` rule
- Unused variable rules → linter
- Custom project rules ("no `console.log` in production code") → ESLint custom rule, not CLAUDE.md prose

If the project doesn't have the linter config yet, propose adding it AS PART of xforge output.

## What to displace to CI

- "Always write tests" → CI coverage gate
- "Format before commit" → pre-commit hook via `pre-commit`, `husky`, or `lefthook`
- "Type-check before commit" → same

## What STAYS in CLAUDE.md

After displacement, CLAUDE.md holds only:

- Behavioral framing — "Fix root causes, not symptoms", anti-slop preamble
- Planning workflow — plan mode first, phased execution
- Project-specific architecture — data flows, non-obvious patterns, domain invariants
- PROTECTED rules (see `line-classification.md`) — safety/compliance rules that also need human-readable doc
- The "When Corrected" self-improvement protocol

Rule of thumb: if you could write a hook or set a permission rule that makes the rule automatic, DISPLACE. If the rule requires Claude to exercise judgment, KEEP.

## Audit output format

When running the displacement audit, output:

```
### Settings-Displacement Candidates

Line N: "<rule verbatim>"
  → settings.json: `<config snippet>`
  → Reason: deterministic once moved, advisory where it is

Line M: "<rule verbatim>"
  → Hook: PostToolUse on Write|Edit with `if: "Write(**/*.py)"`
  → Reason: runs every time, never forgotten

<repeat per candidate>

Net effect: ~<N> lines removable from CLAUDE.md once displaced.
```

Displacement reduces CLAUDE.md size while INCREASING enforcement — a free win.
