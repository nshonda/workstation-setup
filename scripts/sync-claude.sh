#!/usr/bin/env bash
set -euo pipefail

# Sync Claude Code config files (hooks, skills, agents, config) without
# touching credentials, MCP servers, direnv, or plugins.
# Safe to run anytime after editing files in claude/.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$REPO_DIR/claude"

echo "=== Syncing Claude Code config ==="

mkdir -p ~/.claude/hooks ~/.claude/skills ~/.claude/agents ~/.claude/includes

SYNCED=0

# CLAUDE.md
if [[ -f "$CLAUDE_DIR/config/CLAUDE.md" ]]; then
    cp "$CLAUDE_DIR/config/CLAUDE.md" ~/.claude/CLAUDE.md
    echo "  CLAUDE.md"
    SYNCED=$((SYNCED + 1))
fi

# RTK.md
if [[ -f "$CLAUDE_DIR/config/RTK.md" ]]; then
    cp "$CLAUDE_DIR/config/RTK.md" ~/.claude/RTK.md
    echo "  RTK.md"
    SYNCED=$((SYNCED + 1))
fi

# includes/
if [[ -d "$CLAUDE_DIR/config/includes" ]]; then
    cp -R "$CLAUDE_DIR/config/includes/"* ~/.claude/includes/
    echo "  includes/"
    SYNCED=$((SYNCED + 1))
fi

# settings.json — merge with existing (same as setup-claude.sh)
if [[ -f "$CLAUDE_DIR/config/settings.json" ]]; then
    if [[ -f ~/.claude/settings.json ]]; then
        TEMP_SETTINGS=$(mktemp)
        jq -s '.[0] * .[1]' ~/.claude/settings.json "$CLAUDE_DIR/config/settings.json" > "$TEMP_SETTINGS"
        mv "$TEMP_SETTINGS" ~/.claude/settings.json
        echo "  settings.json (merged)"
    else
        cp "$CLAUDE_DIR/config/settings.json" ~/.claude/settings.json
        echo "  settings.json"
    fi
    SYNCED=$((SYNCED + 1))
fi

# Skills
if [[ -d "$CLAUDE_DIR/skills" ]]; then
    cp -R "$CLAUDE_DIR/skills/"* ~/.claude/skills/ 2>/dev/null || true
    echo "  skills/"
    SYNCED=$((SYNCED + 1))
fi

# Agents
if [[ -d "$CLAUDE_DIR/agents" ]]; then
    cp -R "$CLAUDE_DIR/agents/"* ~/.claude/agents/ 2>/dev/null || true
    echo "  agents/"
    SYNCED=$((SYNCED + 1))
fi

# Hooks
if [[ -d "$CLAUDE_DIR/hooks" ]]; then
    cp -R "$CLAUDE_DIR/hooks/"* ~/.claude/hooks/ 2>/dev/null || true
    chmod +x ~/.claude/hooks/* 2>/dev/null || true
    echo "  hooks/"
    SYNCED=$((SYNCED + 1))
fi

# init-project-claude
if [[ -f "$REPO_DIR/scripts/init-project-claude.sh" ]]; then
    cp "$REPO_DIR/scripts/init-project-claude.sh" ~/.local/bin/init-project-claude
    chmod +x ~/.local/bin/init-project-claude
    echo "  init-project-claude"
    SYNCED=$((SYNCED + 1))
fi

# Hookify rules
for rule in "$CLAUDE_DIR/config"/hookify.*.local.md; do
    [[ -f "$rule" ]] || continue
    cp "$rule" ~/.claude/
    echo "  $(basename "$rule")"
    SYNCED=$((SYNCED + 1))
done

echo ""
echo "Synced $SYNCED items. Restart Claude Code to pick up changes."
