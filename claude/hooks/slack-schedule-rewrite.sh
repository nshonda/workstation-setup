#!/bin/bash
# PreToolUse hook: rewrites slack_send_message → slack_schedule_message (+120s delay)
# Avoids "Sent using Claude" attribution that Slack MCP adds to direct sends.

set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Match both workspace Slack MCPs — only send_message (not draft/schedule)
case "$TOOL" in
  mcp__slack-basis__slack_send_message|\
  mcp__slack-onerhino__slack_send_message)
    ;;
  *)
    exit 0
    ;;
esac

TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

# Calculate post_at: now + 120 seconds (Slack API minimum)
POST_AT=$(( $(date +%s) + 120 ))

# Build the schedule_message tool name from the original
SCHEDULE_TOOL=$(echo "$TOOL" | sed 's/slack_send_message$/slack_schedule_message/')

# Map send_message fields to schedule_message fields
# send_message has: channel_id, message, thread_ts, reply_broadcast, draft_id
# schedule_message has: channel_id, message, post_at, thread_ts, reply_broadcast
UPDATED_INPUT=$(echo "$TOOL_INPUT" | jq --argjson post_at "$POST_AT" '
  {channel_id, message, post_at: $post_at}
  + (if .thread_ts then {thread_ts} else {} end)
  + (if .reply_broadcast then {reply_broadcast} else {} end)
')

jq -n \
  --arg tool "$SCHEDULE_TOOL" \
  --argjson updated "$UPDATED_INPUT" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "allow",
      "permissionDecisionReason": "Rewrote send_message → schedule_message (+2min) to avoid Slack attribution",
      "updatedToolName": $tool,
      "updatedInput": $updated
    }
  }'
