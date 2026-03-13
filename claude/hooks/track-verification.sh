#!/bin/bash
# PostToolUse:Bash hook — tracks successful test/typecheck runs
# Writes markers to /tmp/claude-verify-{key}.json so verify-before-commit.sh
# can check whether verification passed before allowing commits.

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_output.exit_code // empty')

# Only care about successful commands
if [ -z "$CMD" ] || [ "$EXIT_CODE" != "0" ]; then
  exit 0
fi

# Compute session key: hash of git repo root + branch (stable across subdirs)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
KEY=$(echo "${REPO_ROOT}:${BRANCH}" | shasum -a 256 | cut -c1-12)
MARKER_FILE="/tmp/claude-verify-${KEY}.json"

# Initialize marker file if it doesn't exist
if [ ! -f "$MARKER_FILE" ]; then
  echo '{}' > "$MARKER_FILE"
fi

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Detect test runners
if echo "$CMD" | grep -qE '\b(vitest|jest|pytest|mocha|ava)\b|npm\s+(test|run\s+test)\b'; then
  CURRENT=$(cat "$MARKER_FILE")
  echo "$CURRENT" | jq --arg ts "$NOW" '.tests_passed = $ts' > "$MARKER_FILE"
fi

# Detect typecheck
if echo "$CMD" | grep -qE '\btsc\b.*--noEmit'; then
  CURRENT=$(cat "$MARKER_FILE")
  echo "$CURRENT" | jq --arg ts "$NOW" '.typecheck_passed = $ts' > "$MARKER_FILE"
fi

exit 0
