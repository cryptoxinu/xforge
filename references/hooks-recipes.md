# Hooks Recipes — Verified Syntax

All examples verified against `code.claude.com/docs/en/hooks` (2026-04). The previous xforge version had INCORRECT hook syntax; this file is the authoritative replacement. If you see `{"tool_name": "...", "file_glob": "..."}` anywhere, it's wrong — replace with the form below.

## Key facts

- **Matcher is a string**, not an object. Examples: `"Bash"`, `"Write|Edit"`, `"mcp__memory__.*"` (regex)
- **File/command targeting uses the `if` field** inside the command spec, not the matcher
- **Hook types**: `command`, `http`, `prompt`, `agent`
- **Exit codes**: `0` = success, `2` = BLOCKING (stderr fed to Claude, action blocked), other = non-blocking error
- **Exit 1 is NON-blocking** — unlike Unix convention. Use `2` to enforce policy.
- **JSON response shapes differ by event** — `decision` field for some, `hookSpecificOutput` for others

## Event catalog (current, verified)

Lifecycle: `SessionStart` · `UserPromptSubmit` · `PreToolUse` · `PermissionRequest` · `PermissionDenied` · `PostToolUse` · `PostToolUseFailure` · `Notification` · `SubagentStart` · `SubagentStop` · `TaskCreated` · `TaskCompleted` · `Stop` · `StopFailure` · `TeammateIdle` · `InstructionsLoaded` · `ConfigChange` · `CwdChanged` · `FileChanged` · `WorktreeCreate` · `WorktreeRemove` · `PreCompact` · `PostCompact` · `Elicitation` · `ElicitationResult` · `SessionEnd`

Matcher filter key varies by event:
- `PreToolUse` / `PostToolUse` / `PermissionRequest` / `PermissionDenied` → tool name
- `SessionStart` → `"startup"`, `"resume"`, `"clear"`, `"compact"`
- `SubagentStart` / `SubagentStop` → agent type
- `InstructionsLoaded` → `"session_start"`, `"nested_traversal"`, `"path_glob_match"`
- `UserPromptSubmit` / `Stop` / `TaskCreated` / `TaskCompleted` → no matcher (always fires)

## Recipe 1: Auto-format on file write

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
          },
          {
            "type": "command",
            "if": "Write(**/*.go) || Edit(**/*.go)",
            "command": "cd \"$CLAUDE_PROJECT_DIR\" && gofmt -w . 2>/dev/null"
          },
          {
            "type": "command",
            "if": "Write(**/*.rs) || Edit(**/*.rs)",
            "command": "cd \"$CLAUDE_PROJECT_DIR\" && cargo fmt 2>/dev/null"
          }
        ]
      }
    ]
  }
}
```

## Recipe 2: Block destructive `rm -rf`

Script `.claude/hooks/block-rm.sh`:

```bash
#!/usr/bin/env bash
COMMAND=$(jq -r '.tool_input.command')
if echo "$COMMAND" | grep -qE 'rm -rf|rm -fr|rm --recursive'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Destructive rm blocked by hook. Use targeted paths or trash instead."
    }
  }'
  exit 0
fi
exit 0
```

Settings:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(rm *)",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-rm.sh"
          }
        ]
      }
    ]
  }
}
```

Make the script executable: `chmod +x .claude/hooks/block-rm.sh`.

## Recipe 3: Block `git push` without confirmation

Simple version via permissions (recommended):
```json
{
  "permissions": {
    "ask": [
      "Bash(git push*)"
    ]
  }
}
```

Hook version (more flexible, can inspect the branch):
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(git push*)",
            "command": "jq -n '{hookSpecificOutput: {hookEventName: \"PreToolUse\", permissionDecision: \"ask\", permissionDecisionReason: \"Confirm you want to push — check for concurrent sessions first.\"}}'"
          }
        ]
      }
    ]
  }
}
```

## Recipe 4: Stop hook — block session completion when tests fail

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cd \"$CLAUDE_PROJECT_DIR\" && pytest tests/ -q 2>&1 | tail -10; RC=${PIPESTATUS[0]}; if [ $RC -ne 0 ]; then jq -n --arg r \"Tests failing (exit $RC). Fix before completing.\" '{decision: \"block\", reason: $r}'; fi"
          }
        ]
      }
    ]
  }
}
```

For TypeScript:
```json
"command": "cd \"$CLAUDE_PROJECT_DIR\" && npx tsc --noEmit 2>&1 | tail -5; if [ $? -ne 0 ]; then jq -n '{decision:\"block\", reason:\"Type errors present. Fix before completing.\"}'; fi"
```

## Recipe 5: Log all permission requests (debugging)

```json
{
  "hooks": {
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -c '. + {ts: now}' >> \"$CLAUDE_PROJECT_DIR/.claude/permission-log.jsonl\""
          }
        ]
      }
    ]
  }
}
```

Review with `jq . .claude/permission-log.jsonl | less`.

## Recipe 6: InstructionsLoaded — debug which files actually load

When a rule isn't being followed, use this to confirm it was loaded:

```json
{
  "hooks": {
    "InstructionsLoaded": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -c . >> \"$CLAUDE_PROJECT_DIR/.claude/instructions-loaded.jsonl\""
          }
        ]
      }
    ]
  }
}
```

Each entry shows the file path + load reason (`session_start`, `nested_traversal`, `path_glob_match`). Invaluable for debugging `.claude/rules/` with `paths:` scoping.

## Recipe 7: SessionStart staleness / drift warning

Fires at session start. Catches the most common CLAUDE.md drift without running a full audit: commit distance + config file changes since CLAUDE.md was last updated. Pure git + bash, zero AI/token cost.

Script `.claude/hooks/check-staleness.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$CLAUDE_PROJECT_DIR"

[ -f CLAUDE.md ] || exit 0
[ -d .git ] || exit 0

LAST_HASH=$(git log -1 --format=%H -- CLAUDE.md 2>/dev/null || echo "")
if [ -z "$LAST_HASH" ]; then
  echo "Warning: CLAUDE.md is not tracked by git."
  exit 0
fi

COMMITS_SINCE=$(git rev-list --count "${LAST_HASH}..HEAD" 2>/dev/null || echo "0")
LAST_TS=$(git log -1 --format=%ct -- CLAUDE.md 2>/dev/null || echo "0")
DAYS_SINCE=$(( ( $(date +%s) - LAST_TS ) / 86400 ))

WARNINGS=""

if [ "$COMMITS_SINCE" -gt 50 ]; then
  WARNINGS="${WARNINGS}CLAUDE.md is ${COMMITS_SINCE} commits behind HEAD (last updated ${DAYS_SINCE} days ago). Run /xforge score to check for drift.\n"
fi

for CONFIG in package.json Makefile pyproject.toml Cargo.toml go.mod; do
  if [ -f "$CONFIG" ]; then
    CHANGED=$(git diff --name-only "$LAST_HASH"..HEAD -- "$CONFIG" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CHANGED" -gt 0 ]; then
      WARNINGS="${WARNINGS}${CONFIG} changed since CLAUDE.md was last updated — build/test commands may be stale.\n"
    fi
  fi
done

if [ -n "$WARNINGS" ]; then
  printf "⚠ CLAUDE.md Staleness Warning:\n${WARNINGS}"
fi
```

Settings:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-staleness.sh",
            "statusMessage": "Checking CLAUDE.md freshness..."
          }
        ]
      }
    ]
  }
}
```

Make executable: `chmod +x .claude/hooks/check-staleness.sh`.

## Recipe 8: Scrub PHI from written files (domain-critical)

Script `.claude/hooks/phi-scrub.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
CONTENT=$(jq -r '.tool_input.content // .tool_input.new_string // ""')
# Pattern: SSN-like, DOB-like, long digit runs that could be MRN
if echo "$CONTENT" | grep -qE '\b\d{3}-\d{2}-\d{4}\b|\b\d{10,}\b|\b\d{2}/\d{2}/\d{4}\b'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Potential PHI pattern detected. Write through the scrubber (src/phi/scrubber.py) or confirm this is safe."
    }
  }'
fi
exit 0
```

Settings:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/phi-scrub.sh"
          }
        ]
      }
    ]
  }
}
```

## Environment variables available inside hooks

- `$CLAUDE_PROJECT_DIR` — project root
- `$CLAUDE_PLUGIN_ROOT` — plugin installation dir (plugin hooks)
- `$CLAUDE_PLUGIN_DATA` — plugin persistent data dir

## JSON input via stdin (for command hooks)

Common fields on every event:
```json
{
  "session_id": "abc",
  "transcript_path": "...",
  "cwd": "...",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse"
}
```

Tool events add: `tool_name`, `tool_input`, `tool_use_id`. Subagent events add: `agent_id`, `agent_type`.

## JSON response patterns

**Pattern 1** — `decision` at top level (PostToolUse, Stop, UserPromptSubmit):
```json
{"decision": "block", "reason": "...", "continue": true, "suppressOutput": false}
```

**Pattern 2** — `hookSpecificOutput` (PreToolUse, PermissionRequest):
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask|defer",
    "permissionDecisionReason": "...",
    "updatedInput": { "command": "safer-command" },
    "additionalContext": "..."
  }
}
```

`defer` pauses for an external handler (only valid in `-p` headless mode).

## Testing hooks

Before wiring a hook into real settings, test it by piping sample JSON to the script manually:

```bash
echo '{"session_id":"test","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"rm -rf /tmp"}}' | .claude/hooks/block-rm.sh
```

Then inspect the stdout. If it exits 2 or produces the right JSON, the hook works.

## Gotchas

- **Pipefail in shell hooks** — use `set -euo pipefail` to catch errors early. A missing `jq` makes the hook silently fail.
- **Quoting** — always quote `"$CLAUDE_PROJECT_DIR"` and paths inside commands.
- **Exit 1 vs Exit 2** — remember exit 1 is NON-blocking in Claude Code. This bites people coming from Unix conventions. Use exit 2 to block.
- **Matcher regex** — `"Bash"` exact match, `"Bash|Edit"` alternation, anything else is regex. Be explicit.
- **Timeouts** — default hook timeout is 60s. For slow gates (full test suite), increase with `"timeout": 600`.
