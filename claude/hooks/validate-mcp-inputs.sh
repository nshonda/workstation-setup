#!/bin/bash
# PreToolUse hook: validates required fields and format for Jira/Redmine MCP mutations.
# Blocks calls with missing issue keys or malformed IDs.

set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

case "$TOOL" in
  mcp__jira-basis__jira_update_issue|\
  mcp__jira-basis__jira_transition_issue|\
  mcp__jira-basis__jira_add_comment|\
  mcp__jira-basis__jira_add_worklog)
    ISSUE_KEY=$(echo "$TOOL_INPUT" | jq -r '.issueIdOrKey // empty')
    if [ -z "$ISSUE_KEY" ]; then
      jq -n '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"block","permissionDecisionReason":"Missing issueIdOrKey. Cannot update a Jira issue without specifying which one."}}'
      exit 0
    fi
    if ! echo "$ISSUE_KEY" | grep -qE '^[A-Z][A-Z0-9]+-[0-9]+$'; then
      jq -n --arg key "$ISSUE_KEY" '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"block","permissionDecisionReason":"Invalid issue key format: \($key). Expected PROJ-123 format."}}'
      exit 0
    fi
    ;;
  mcp__redmine-onerhino__redmine_request)
    METHOD=$(echo "$TOOL_INPUT" | jq -r '.method // empty')
    PATH_VAL=$(echo "$TOOL_INPUT" | jq -r '.path // empty')
    if [ "$METHOD" = "PUT" ] || [ "$METHOD" = "DELETE" ]; then
      if ! echo "$PATH_VAL" | grep -qE '/[0-9]+\.json$'; then
        jq -n --arg p "$PATH_VAL" '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"block","permissionDecisionReason":"Destructive Redmine request to path without numeric ID: \($p). Verify the resource exists first."}}'
        exit 0
      fi
    fi
    ;;
  *)
    # Not a targeted tool — pass through
    exit 0
    ;;
esac
