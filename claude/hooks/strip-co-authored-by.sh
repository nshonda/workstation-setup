#!/bin/bash
# PreToolUse:Bash hook — strips self-attribution from git/gh commands.
# Removes Co-Authored-By lines, "Generated with Claude Code", and similar.
# Runs BEFORE rtk-rewrite so it catches the raw command.

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$CMD" ]; then
  exit 0
fi

DIRTY=false

# Patterns to strip (case-insensitive check, case-insensitive removal)
# 1. Co-Authored-By lines (any variant)
if echo "$CMD" | grep -qiE 'Co-Authored-By'; then
  DIRTY=true
fi

# 2. "Generated with Claude Code" / "Written by Claude" / self-attribution
if echo "$CMD" | grep -qiE 'Generated with.*(Claude|claude)|Written by Claude|🤖.*Claude'; then
  DIRTY=true
fi

if [ "$DIRTY" = false ]; then
  exit 0
fi

# Only act on commands that produce output visible to others
if ! echo "$CMD" | grep -qE '(git\s+commit|gh\s+pr|gh\s+issue)'; then
  exit 0
fi

CLEANED="$CMD"

# Strip Co-Authored-By lines
CLEANED=$(echo "$CLEANED" | sed -E '/^[[:space:]]*Co-[Aa]uthored-[Bb]y:/d')
CLEANED=$(echo "$CLEANED" | sed -E 's/[[:space:]]*Co-[Aa]uthored-[Bb]y:[^\\]*//g')
CLEANED=$(echo "$CLEANED" | sed -E 's/\\nCo-[Aa]uthored-[Bb]y:[^"]*//g')

# Strip "Generated with Claude Code" lines and emoji variants
CLEANED=$(echo "$CLEANED" | sed -E '/^[[:space:]]*(🤖|\\xF0\\x9F\\xA4\\x96)?[[:space:]]*(Generated with|Written by).*[Cc]laude/d')
CLEANED=$(echo "$CLEANED" | sed -E 's/\\n[[:space:]]*(🤖|\\xF0\\x9F\\xA4\\x96)?[[:space:]]*(Generated with|Written by).*[Cc]laude[^"]*//g')
CLEANED=$(echo "$CLEANED" | sed -E 's/(🤖|\\xF0\\x9F\\xA4\\x96)?[[:space:]]*(Generated with|Written by).*[Cc]laude[^"]*//g')

# Clean up trailing whitespace
CLEANED=$(echo "$CLEANED" | sed -E 's/[[:space:]]+$//')

# Build updated tool_input
ORIGINAL_INPUT=$(echo "$INPUT" | jq -c '.tool_input')
UPDATED_INPUT=$(echo "$ORIGINAL_INPUT" | jq --arg cmd "$CLEANED" '.command = $cmd')

jq -n \
  --argjson updated "$UPDATED_INPUT" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "allow",
      "permissionDecisionReason": "Stripped self-attribution per CLAUDE.md policy",
      "updatedInput": $updated
    }
  }'
