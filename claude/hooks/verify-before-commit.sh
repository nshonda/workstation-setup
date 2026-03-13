#!/bin/bash
# PreToolUse:Bash hook — blocks git commit unless tests and typecheck have passed.
# Reads markers written by track-verification.sh (PostToolUse companion).
# Only enforces in JS/TS projects (detected via package.json / tsconfig.json).

set -euo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$CMD" ]; then
  exit 0
fi

# Only intercept git commit commands
if ! echo "$CMD" | grep -qE '\bgit\s+commit\b'; then
  exit 0
fi

# Detect working directory (handle "cd <path> && git commit" pattern)
GIT_WORKDIR=""
if echo "$CMD" | grep -qE '^\s*cd\s+'; then
  GIT_WORKDIR=$(echo "$CMD" | sed -E 's|^\s*cd\s+([^ ]+)\s*&&.*|\1|')
elif echo "$CMD" | grep -qE 'git\s+-C\s+'; then
  GIT_WORKDIR=$(echo "$CMD" | sed -E 's|.*git\s+-C\s+([^ ]+)\s+commit.*|\1|')
fi

CHECK_DIR="${GIT_WORKDIR:-$PWD}"

# Resolve to absolute path
if [[ "$CHECK_DIR" != /* ]]; then
  CHECK_DIR="$PWD/$CHECK_DIR"
fi

# Find package.json — check current dir and parent (for monorepo subdirs like backend/)
PACKAGE_JSON=""
if [ -f "$CHECK_DIR/package.json" ]; then
  PACKAGE_JSON="$CHECK_DIR/package.json"
elif [ -f "$(dirname "$CHECK_DIR")/package.json" ]; then
  PACKAGE_JSON="$(dirname "$CHECK_DIR")/package.json"
fi

# Find tsconfig.json — same search pattern
TSCONFIG=""
if [ -f "$CHECK_DIR/tsconfig.json" ]; then
  TSCONFIG="$CHECK_DIR/tsconfig.json"
elif [ -f "$(dirname "$CHECK_DIR")/tsconfig.json" ]; then
  TSCONFIG="$(dirname "$CHECK_DIR")/tsconfig.json"
fi

# Not a JS/TS project — allow commit
if [ -z "$PACKAGE_JSON" ] && [ -z "$TSCONFIG" ]; then
  exit 0
fi

# Compute session key (same as track-verification.sh — uses repo root, not cwd)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
KEY=$(echo "${REPO_ROOT}:${BRANCH}" | shasum -a 256 | cut -c1-12)
MARKER_FILE="/tmp/claude-verify-${KEY}.json"

# Build list of missing checks
MISSING=""

# Check tests — only if package.json has a test script
if [ -n "$PACKAGE_JSON" ]; then
  HAS_TEST=$(jq -r '.scripts.test // empty' "$PACKAGE_JSON")
  if [ -n "$HAS_TEST" ] && [ "$HAS_TEST" != "echo \"Error: no test specified\" && exit 1" ]; then
    TESTS_PASSED=$([ -f "$MARKER_FILE" ] && jq -r '.tests_passed // empty' "$MARKER_FILE" || echo "")
    if [ -z "$TESTS_PASSED" ]; then
      MISSING="${MISSING}tests (run: npm test or npx vitest run), "
    fi
  fi
fi

# Check typecheck — only if tsconfig.json exists
if [ -n "$TSCONFIG" ]; then
  TYPECHECK_PASSED=$([ -f "$MARKER_FILE" ] && jq -r '.typecheck_passed // empty' "$MARKER_FILE" || echo "")
  if [ -z "$TYPECHECK_PASSED" ]; then
    MISSING="${MISSING}typecheck (run: npx tsc --noEmit), "
  fi
fi

# If nothing missing, allow commit and clear markers
if [ -z "$MISSING" ]; then
  # Clear markers for next commit cycle
  rm -f "$MARKER_FILE"
  exit 0
fi

# Strip trailing comma+space
MISSING="${MISSING%, }"

# Block the commit
jq -n --arg reason "BLOCKED: Cannot commit without passing verification. Missing: ${MISSING}" '{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": $reason
  }
}'
exit 0
