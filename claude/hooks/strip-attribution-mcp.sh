#!/bin/bash
# PreToolUse hook for GitHub MCP tools — strips self-attribution from body/content fields.
# Catches: Co-Authored-By, "Generated with Claude Code", "Written by Claude", etc.

set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only act on GitHub MCP tools that produce visible output
case "$TOOL" in
  mcp__plugin_github_github__create_pull_request|\
  mcp__plugin_github_github__update_pull_request|\
  mcp__plugin_github_github__add_issue_comment|\
  mcp__plugin_github_github__add_comment_to_pending_review|\
  mcp__plugin_github_github__add_reply_to_pull_request_comment|\
  mcp__plugin_github_github__create_or_update_file|\
  mcp__plugin_github_github__issue_write|\
  mcp__plugin_github_github__pull_request_review_write)
    ;;
  *)
    exit 0
    ;;
esac

TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

# Check all string fields for attribution patterns
if ! echo "$TOOL_INPUT" | grep -qiE 'Co-Authored-By|Generated with.*[Cc]laude|Written by Claude|🤖.*[Cc]laude'; then
  exit 0
fi

# Strip attribution from every string value in tool_input
CLEANED=$(echo "$TOOL_INPUT" | jq '
  walk(
    if type == "string" then
      # Strip Co-Authored-By lines
      gsub("\\nCo-[Aa]uthored-[Bb]y:[^\\n]*"; "") |
      gsub("Co-[Aa]uthored-[Bb]y:[^\\n]*"; "") |
      # Strip Generated with Claude Code (with optional emoji and markdown link)
      gsub("\\n+[[:space:]]*(🤖[[:space:]]*)?Generated with[^\\n]*[Cc]laude[^\\n]*"; "") |
      gsub("(🤖[[:space:]]*)?Generated with[^\\n]*[Cc]laude[^\\n]*"; "") |
      # Strip Written by Claude
      gsub("\\n+[[:space:]]*Written by Claude[^\\n]*"; "") |
      gsub("Written by Claude[^\\n]*"; "") |
      # Clean trailing whitespace
      gsub("[[:space:]]+$"; "")
    else .
    end
  )
')

jq -n \
  --argjson updated "$CLEANED" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "allow",
      "permissionDecisionReason": "Stripped self-attribution from GitHub MCP call per CLAUDE.md policy",
      "updatedInput": $updated
    }
  }'
