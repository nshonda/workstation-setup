#!/bin/bash
# PreToolUse:Bash hook — blocks commits and pushes on protected branches
# (main, master) and all force-push operations. Hard block with deny decision.

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$CMD" ]; then
  exit 0
fi

# Block 0: Committing while on main/master
if echo "$CMD" | grep -qE '\bgit\s+commit\b'; then
  # Detect working directory: handle "cd <path> && git commit" and "git -C <path> commit"
  GIT_WORKDIR=""
  if echo "$CMD" | grep -qE '^\s*cd\s+'; then
    GIT_WORKDIR=$(echo "$CMD" | sed -E 's|^\s*cd\s+([^ ]+)\s*&&.*|\1|')
  elif echo "$CMD" | grep -qE 'git\s+-C\s+'; then
    GIT_WORKDIR=$(echo "$CMD" | sed -E 's|.*git\s+-C\s+([^ ]+)\s+commit.*|\1|')
  fi
  if [ -n "$GIT_WORKDIR" ]; then
    CURRENT_BRANCH=$(git -C "$GIT_WORKDIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  else
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  fi
  if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "BLOCKED: Committing on main/master is not allowed. Create a feature branch first (git checkout -b <branch-name>)."
      }
    }'
    exit 0
  fi
fi

# Only check git push commands from here
if ! echo "$CMD" | grep -qE '\bgit\s+push\b'; then
  exit 0
fi

# Block 1: Force push — allow --force-with-lease on non-protected branches, block all others
if echo "$CMD" | grep -qE '\bgit\s+push\b.*\s(-f|--force)(\s|$)' && ! echo "$CMD" | grep -qE '\bgit\s+push\b.*--force-with-lease'; then
  jq -n '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": "BLOCKED: Force push (--force) is not allowed. Use --force-with-lease for rebased branches or a regular push."
    }
  }'
  exit 0
fi

# Block --force-with-lease to protected branches
if echo "$CMD" | grep -qE '\bgit\s+push\b.*--force-with-lease'; then
  if echo "$CMD" | grep -qE '\bgit\s+push\b.*\b(main|master)\b'; then
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "BLOCKED: Force push to main/master is not allowed, even with --force-with-lease."
      }
    }'
    exit 0
  fi
fi

# Block 2: Push directly to main or master
# Catches: git push origin main, git push origin HEAD:main, git push (when on main)
TARGETS_PROTECTED=false

# Explicit branch name in command
if echo "$CMD" | grep -qE '\bgit\s+push\b.*\b(main|master)\b'; then
  TARGETS_PROTECTED=true
fi

# Push with HEAD:main or HEAD:refs/heads/main
if echo "$CMD" | grep -qE '\bgit\s+push\b.*HEAD:(refs/heads/)?(main|master)'; then
  TARGETS_PROTECTED=true
fi

# Bare "git push" or "git push origin" — check current branch
if echo "$CMD" | grep -qE '^\s*git\s+push\s*$|^\s*git\s+push\s+\S+\s*$'; then
  GIT_PUSH_WORKDIR=""
  if echo "$CMD" | grep -qE '^\s*cd\s+'; then
    GIT_PUSH_WORKDIR=$(echo "$CMD" | sed -E 's|^\s*cd\s+([^ ]+)\s*&&.*|\1|')
  fi
  if [ -n "$GIT_PUSH_WORKDIR" ]; then
    CURRENT_BRANCH=$(git -C "$GIT_PUSH_WORKDIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  else
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  fi
  if [ "$CURRENT_BRANCH" = "main" ] || [ "$CURRENT_BRANCH" = "master" ]; then
    TARGETS_PROTECTED=true
  fi
fi

if [ "$TARGETS_PROTECTED" = true ]; then
  jq -n '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": "BLOCKED: Direct push to main/master is not allowed. Create a feature branch and open a PR instead."
    }
  }'
  exit 0
fi

# All other pushes are fine
exit 0
