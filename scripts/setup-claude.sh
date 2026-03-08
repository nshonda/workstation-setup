#!/usr/bin/env bash
set -euo pipefail

# Claude Code Setup
# Installs MCP servers, deploys config/skills/hooks, configures direnv + credentials

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$REPO_DIR/claude"

echo "=== Claude Code Setup ==="
echo ""

# Require identity env vars from setup.sh (or export them before running standalone)
: "${WS_PERSONAL_GH_USER:?Set WS_PERSONAL_GH_USER before running this script}"
: "${WS_WORK_GH_USER:?Set WS_WORK_GH_USER before running this script}"

# Optional vars — default to empty if not set
GH_PERSONAL_TOKEN="${GH_PERSONAL_TOKEN:-}"
GH_WORK_TOKEN="${GH_WORK_TOKEN:-}"
JIRA_URL="${JIRA_URL:-}"
JIRA_EMAIL="${JIRA_EMAIL:-}"
JIRA_TOKEN="${JIRA_TOKEN:-}"
REDMINE_URL="${REDMINE_URL:-}"
REDMINE_KEY="${REDMINE_KEY:-}"
CONTEXT7_KEY="${CONTEXT7_KEY:-}"
GCS_BUCKET="${GCS_BUCKET:-}"

# Strip protocol/trailing slash from URLs if present
JIRA_URL="${JIRA_URL#https://}"; JIRA_URL="${JIRA_URL#http://}"; JIRA_URL="${JIRA_URL%/}"
REDMINE_URL="${REDMINE_URL#https://}"; REDMINE_URL="${REDMINE_URL#http://}"; REDMINE_URL="${REDMINE_URL%/}"

# ---------- Platform detection ----------

OS="$(uname -s)"
case "$OS" in
    Darwin) PLATFORM="mac" ;;
    Linux)  PLATFORM="linux" ;;
    *)      echo "Unsupported platform: $OS"; exit 1 ;;
esac

# ---------- 1. Install uv ----------

echo "--- Installing dependencies ---"
if ! command -v uv &>/dev/null; then
    if [[ "$PLATFORM" == "mac" ]]; then
        brew install uv
    else
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    echo "uv installed"
else
    echo "uv already installed"
fi

if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required. Install it first (brew install jq / apt install jq)."
    exit 1
fi

# ---------- 3. Store credentials in keychain ----------

echo ""
echo "--- Storing credentials ---"

store_credential() {
    local service="$1" account="$2" label="$3" value="$4"
    [[ -z "$value" ]] && return 0
    if [[ "$PLATFORM" == "mac" ]]; then
        security delete-generic-password -s "$service" -a "$account" 2>/dev/null || true
        security add-generic-password -s "$service" -a "$account" -w "$value"
    else
        echo -n "$value" | secret-tool store --label="$label" service "$service" username "$account"
    fi
    echo "  Stored: $service"
}

if [[ "$PLATFORM" == "linux" ]]; then
    if ! command -v secret-tool &>/dev/null; then
        echo "ERROR: secret-tool not found. Run setup-wsl.sh first to install keyring packages."
        exit 1
    fi
    if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
        eval "$(dbus-launch --sh-syntax)"
    fi
    eval "$(echo '' | gnome-keyring-daemon --unlock --components=secrets 2>/dev/null)" || true
fi

store_credential "github-personal" "api-token" "GitHub Personal Token" "$GH_PERSONAL_TOKEN"
store_credential "github-work" "api-token" "GitHub Work Token" "$GH_WORK_TOKEN"
store_credential "jira-basis" "api-token" "Jira Work API Token" "$JIRA_TOKEN"
store_credential "redmine-onerhino" "api-key" "Redmine Personal API Key" "$REDMINE_KEY"
echo "Credentials stored"

# ---------- 4. Create MCP wrapper scripts ----------

echo ""
echo "--- Creating MCP wrapper scripts ---"

mkdir -p ~/.local/bin

if [[ -n "$JIRA_URL" ]]; then
cat > ~/.local/bin/mcp-jira-basis-wrapper << EOF
#!/bin/bash
# Wrapper script for mcp-atlassian that fetches credentials from keychain
export JIRA_URL="https://${JIRA_URL}"
export JIRA_USERNAME="${JIRA_EMAIL}"

if [[ "\$OSTYPE" == "darwin"* ]]; then
  export JIRA_API_TOKEN=\$(security find-generic-password -s "jira-basis" -a "api-token" -w 2>/dev/null)
else
  export JIRA_API_TOKEN=\$(secret-tool lookup service jira-basis username api-token 2>/dev/null)
fi

# Confluence uses same Atlassian credentials
export CONFLUENCE_URL="https://${JIRA_URL}/wiki"
export CONFLUENCE_USERNAME="${JIRA_EMAIL}"
export CONFLUENCE_API_TOKEN="\$JIRA_API_TOKEN"

if [ -z "\$JIRA_API_TOKEN" ]; then
  echo "Error: Could not retrieve Jira API token from keychain" >&2
  exit 1
fi

exec uvx mcp-atlassian "\$@"
EOF
echo "Created ~/.local/bin/mcp-jira-basis-wrapper"
fi

if [[ -n "$REDMINE_URL" ]]; then
cat > ~/.local/bin/mcp-redmine-onerhino-wrapper << EOF
#!/bin/bash
# Wrapper script for mcp-redmine that fetches credentials from keychain
export REDMINE_URL="https://${REDMINE_URL}"
export REDMINE_ALLOWED_DIRECTORIES="\$HOME/workstation"

if [[ "\$OSTYPE" == "darwin"* ]]; then
  export REDMINE_API_KEY=\$(security find-generic-password -s "redmine-onerhino" -a "api-key" -w 2>/dev/null)
else
  export REDMINE_API_KEY=\$(secret-tool lookup service redmine-onerhino username api-key 2>/dev/null)
fi

if [ -z "\$REDMINE_API_KEY" ]; then
  echo "Error: Could not retrieve Redmine API key from keychain" >&2
  exit 1
fi

exec uvx --from mcp-redmine mcp-redmine "\$@"
EOF
echo "Created ~/.local/bin/mcp-redmine-onerhino-wrapper"
fi

# chmod wrappers that exist
chmod +x ~/.local/bin/mcp-*-wrapper 2>/dev/null || true

# ---------- 5. Deploy Claude Code config ----------

echo ""
echo "--- Deploying Claude Code config ---"

mkdir -p ~/.claude/hooks ~/.claude/skills ~/.claude/agents

# CLAUDE.md
if [[ -f "$CLAUDE_DIR/config/CLAUDE.md" ]]; then
    cp "$CLAUDE_DIR/config/CLAUDE.md" ~/.claude/CLAUDE.md
    echo "Deployed ~/.claude/CLAUDE.md"
fi

# includes/ directory (referenced by CLAUDE.md via @includes/)
if [[ -d "$CLAUDE_DIR/config/includes" ]]; then
    mkdir -p ~/.claude/includes
    cp -R "$CLAUDE_DIR/config/includes/"* ~/.claude/includes/
    echo "Deployed ~/.claude/includes/"
fi

# RTK.md
if [[ -f "$CLAUDE_DIR/config/RTK.md" ]]; then
    cp "$CLAUDE_DIR/config/RTK.md" ~/.claude/RTK.md
    echo "Deployed ~/.claude/RTK.md"
fi

# settings.json — merge with existing or create new
if [[ -f "$CLAUDE_DIR/config/settings.json" ]]; then
    if [[ -f ~/.claude/settings.json ]]; then
        TEMP_SETTINGS=$(mktemp)
        jq -s '.[0] * .[1]' ~/.claude/settings.json "$CLAUDE_DIR/config/settings.json" > "$TEMP_SETTINGS"
        mv "$TEMP_SETTINGS" ~/.claude/settings.json
        echo "Merged ~/.claude/settings.json"
    else
        cp "$CLAUDE_DIR/config/settings.json" ~/.claude/settings.json
        echo "Deployed ~/.claude/settings.json"
    fi
fi

# settings.local.json — only if doesn't exist
if [[ -f "$CLAUDE_DIR/config/settings.local.json" ]]; then
    if [[ ! -f ~/.claude/settings.local.json ]]; then
        cp "$CLAUDE_DIR/config/settings.local.json" ~/.claude/settings.local.json
        echo "Deployed ~/.claude/settings.local.json"
    else
        echo "~/.claude/settings.local.json already exists, skipping"
    fi
fi

# Skills — copy all
if [[ -d "$CLAUDE_DIR/skills" ]]; then
    cp -R "$CLAUDE_DIR/skills/"* ~/.claude/skills/ 2>/dev/null || true
    # Fill in GCS bucket if provided
    if [[ -n "${GCS_BUCKET:-}" ]] && [[ -f ~/.claude/skills/interactive-plan/SKILL.md ]]; then
        ESCAPED_BUCKET=$(printf '%s\n' "$GCS_BUCKET" | sed 's/[&/\]/\\&/g')
        sed -i.bak "s|<YOUR_GCS_BUCKET>|${ESCAPED_BUCKET}|g" ~/.claude/skills/interactive-plan/SKILL.md
        rm -f ~/.claude/skills/interactive-plan/SKILL.md.bak
    fi
    echo "Deployed skills to ~/.claude/skills/"
fi

# Agents — copy all
if [[ -d "$CLAUDE_DIR/agents" ]]; then
    cp -R "$CLAUDE_DIR/agents/"* ~/.claude/agents/ 2>/dev/null || true
    echo "Deployed agents to ~/.claude/agents/"
fi

# Hooks — copy all, chmod +x
if [[ -d "$CLAUDE_DIR/hooks" ]]; then
    cp -R "$CLAUDE_DIR/hooks/"* ~/.claude/hooks/ 2>/dev/null || true
    chmod +x ~/.claude/hooks/* 2>/dev/null || true
    echo "Deployed hooks to ~/.claude/hooks/"
fi

# init-project-claude — deploy to ~/.local/bin for global access
if [[ -f "$REPO_DIR/scripts/init-project-claude.sh" ]]; then
    cp "$REPO_DIR/scripts/init-project-claude.sh" ~/.local/bin/init-project-claude
    chmod +x ~/.local/bin/init-project-claude
    echo "Deployed ~/.local/bin/init-project-claude"
fi

# Hookify rules — copy *.local.md files
for rule in "$CLAUDE_DIR/config"/hookify.*.local.md; do
    [[ -f "$rule" ]] || continue
    cp "$rule" ~/.claude/
    echo "Deployed ~/.claude/$(basename "$rule")"
done

# ---------- 6. Register MCP servers in ~/.claude.json ----------

echo ""
echo "--- Configuring MCP servers ---"

CLAUDE_CONFIG=~/.claude.json

# Build MCP servers config — start with Slack (always included)
MCP_SERVERS='{
  "slack-onerhino": {
    "type": "http",
    "url": "https://mcp.slack.com/mcp",
    "oauth": {
      "clientId": "1601185624273.8899143856786",
      "callbackPort": 3118
    }
  },
  "slack-basis": {
    "type": "http",
    "url": "https://mcp.slack.com/mcp",
    "oauth": {
      "clientId": "1601185624273.8899143856786",
      "callbackPort": 3118
    }
  }
}'

# Add Jira if configured
if [[ -n "$JIRA_URL" ]]; then
    MCP_SERVERS=$(echo "$MCP_SERVERS" | jq '. + {
      "jira-basis": {
        "type": "stdio",
        "command": "'"$HOME"'/.local/bin/mcp-jira-basis-wrapper",
        "args": []
      }
    }')
fi

# Add Redmine if configured
if [[ -n "$REDMINE_URL" ]]; then
    MCP_SERVERS=$(echo "$MCP_SERVERS" | jq '. + {
      "redmine-onerhino": {
        "type": "stdio",
        "command": "'"$HOME"'/.local/bin/mcp-redmine-onerhino-wrapper",
        "args": []
      }
    }')
fi

# Add Context7 if API key was provided
if [[ -n "$CONTEXT7_KEY" ]]; then
    MCP_SERVERS=$(echo "$MCP_SERVERS" | jq --arg key "$CONTEXT7_KEY" '. + {
      "context7": {
        "type": "http",
        "url": "https://mcp.context7.com/mcp",
        "headers": {
          "CONTEXT7_API_KEY": $key
        }
      }
    }')
fi

if [[ -f "$CLAUDE_CONFIG" ]]; then
    # Merge new servers into existing config
    TEMP_CONFIG=$(mktemp)
    jq --argjson servers "$MCP_SERVERS" '.mcpServers += $servers' "$CLAUDE_CONFIG" > "$TEMP_CONFIG"
    mv "$TEMP_CONFIG" "$CLAUDE_CONFIG"
else
    # Create new config
    echo "$MCP_SERVERS" | jq '{mcpServers: .}' > "$CLAUDE_CONFIG"
fi
echo "Updated ~/.claude.json"

# ---------- 7. Install Claude Code plugins ----------

echo ""
echo "--- Installing plugins ---"

if command -v claude &>/dev/null; then
    claude plugins add anthropics/claude-plugins-official 2>/dev/null || true
    claude plugins add anthropics/skills 2>/dev/null || true
    claude plugins install document-skills@anthropic-agent-skills 2>/dev/null || true
    claude plugins install example-skills@anthropic-agent-skills 2>/dev/null || true
    echo "Plugins installed"
else
    echo "Claude Code CLI not found — install it first, then run:"
    echo "  claude plugins add anthropics/claude-plugins-official"
    echo "  claude plugins add anthropics/skills"
    echo "  claude plugins install document-skills@anthropic-agent-skills"
    echo "  claude plugins install example-skills@anthropic-agent-skills"
fi

# ---------- 8. Create direnv .envrc files ----------

echo ""
echo "--- Setting up direnv ---"

mkdir -p ~/workstation/work ~/workstation/personal

cat > ~/workstation/work/.envrc << EOF
# Work environment — GitHub + Jira credentials
# Credentials fetched from keychain at directory entry

if [[ "\$OSTYPE" == "darwin"* ]]; then
  export GITHUB_TOKEN=\$(security find-generic-password -s "github-work" -a "api-token" -w 2>/dev/null)
  export JIRA_API_TOKEN=\$(security find-generic-password -s "jira-basis" -a "api-token" -w 2>/dev/null)
else
  export GITHUB_TOKEN=\$(secret-tool lookup service github-work username api-token 2>/dev/null)
  export JIRA_API_TOKEN=\$(secret-tool lookup service jira-basis username api-token 2>/dev/null)
fi

$(if [[ -n "$JIRA_URL" ]]; then
cat << JIRA_INNER
export JIRA_URL="https://${JIRA_URL}"
export JIRA_USERNAME="${JIRA_EMAIL}"
JIRA_INNER
fi)

# GitHub MCP plugin expects GITHUB_PERSONAL_ACCESS_TOKEN
export GITHUB_PERSONAL_ACCESS_TOKEN="\$GITHUB_TOKEN"
EOF

cat > ~/workstation/personal/.envrc << EOF
# Personal environment — GitHub + Redmine credentials
# Credentials fetched from keychain at directory entry

if [[ "\$OSTYPE" == "darwin"* ]]; then
  export GITHUB_TOKEN=\$(security find-generic-password -s "github-personal" -a "api-token" -w 2>/dev/null)
  export REDMINE_API_KEY=\$(security find-generic-password -s "redmine-onerhino" -a "api-key" -w 2>/dev/null)
else
  export GITHUB_TOKEN=\$(secret-tool lookup service github-personal username api-token 2>/dev/null)
  export REDMINE_API_KEY=\$(secret-tool lookup service redmine-onerhino username api-key 2>/dev/null)
fi

$(if [[ -n "$REDMINE_URL" ]]; then
cat << REDMINE_INNER
export REDMINE_URL="https://${REDMINE_URL}"
REDMINE_INNER
fi)

# GitHub MCP plugin expects GITHUB_PERSONAL_ACCESS_TOKEN
export GITHUB_PERSONAL_ACCESS_TOKEN="\$GITHUB_TOKEN"
EOF

echo "Created ~/workstation/work/.envrc"
echo "Created ~/workstation/personal/.envrc"

# ---------- 9. Add direnv hook to shell ----------

SHELL_NAME=$(basename "$SHELL")
case "$SHELL_NAME" in
    zsh)
        SHELL_RC=~/.zshrc
        HOOK='eval "$(direnv hook zsh)"'
        ;;
    bash)
        SHELL_RC=~/.bashrc
        HOOK='eval "$(direnv hook bash)"'
        ;;
    *)
        echo "Unknown shell: $SHELL_NAME. Add direnv hook manually."
        SHELL_RC=""
        ;;
esac

if [[ -n "$SHELL_RC" ]] && ! grep -q "direnv hook" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "$HOOK" >> "$SHELL_RC"
    echo "Added direnv hook to $SHELL_RC"
else
    echo "direnv hook already present in $SHELL_RC"
fi

# On Linux, add gnome-keyring startup so secret-tool works in new shells
if [[ "$PLATFORM" == "linux" && -n "$SHELL_RC" ]] && ! grep -q "gnome-keyring-daemon" "$SHELL_RC" 2>/dev/null; then
    cat >> "$SHELL_RC" << 'KEYRING_EOF'

# Start gnome-keyring for secret-tool (direnv credentials)
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
    eval "$(dbus-launch --sh-syntax)"
fi
if ! pgrep -u "$USER" -x gnome-keyring-d >/dev/null 2>&1; then
    eval "$(echo '' | gnome-keyring-daemon --unlock --components=secrets 2>/dev/null)" || true
fi
KEYRING_EOF
    echo "Added gnome-keyring startup to $SHELL_RC"
else
    [[ "$PLATFORM" == "linux" ]] && echo "gnome-keyring startup already present in $SHELL_RC"
fi

# Add GitHub token fallback for Claude Code MCP plugin (directory-dependent)
if [[ -n "$SHELL_RC" ]] && ! grep -q "GitHub token for Claude Code MCP plugin" "$SHELL_RC" 2>/dev/null; then
    if [[ "$PLATFORM" == "mac" ]]; then
        cat >> "$SHELL_RC" << 'GITHUB_EOF'

# GitHub token for Claude Code MCP plugin (directory-dependent)
# Set before direnv as a reliable fallback for MCP plugin initialization
if [[ "$PWD" == "$HOME/workstation/work"* ]]; then
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(security find-generic-password -s "github-work" -a "api-token" -w 2>/dev/null)
elif [[ "$PWD" == "$HOME/workstation/personal"* ]]; then
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(security find-generic-password -s "github-personal" -a "api-token" -w 2>/dev/null)
fi
GITHUB_EOF
    else
        cat >> "$SHELL_RC" << 'GITHUB_EOF'

# GitHub token for Claude Code MCP plugin (directory-dependent)
# Set before direnv as a reliable fallback for MCP plugin initialization
if [[ "$PWD" == "$HOME/workstation/work"* ]]; then
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(secret-tool lookup service github-work username api-token 2>/dev/null)
elif [[ "$PWD" == "$HOME/workstation/personal"* ]]; then
    export GITHUB_PERSONAL_ACCESS_TOKEN=$(secret-tool lookup service github-personal username api-token 2>/dev/null)
fi
GITHUB_EOF
    fi
    echo "Added GitHub token fallback to $SHELL_RC"
else
    echo "GitHub token fallback already present in $SHELL_RC"
fi

direnv allow ~/workstation/work 2>/dev/null || true
direnv allow ~/workstation/personal 2>/dev/null || true
echo "Allowed direnv for workstation directories"

# ---------- 10. Summary ----------

echo ""
echo "=== Claude Code Setup Complete ==="
echo ""
echo "What was configured:"
echo "  - Credentials stored in system keychain"
echo "  - MCP wrapper scripts at ~/.local/bin/"
echo "  - Claude config deployed to ~/.claude/"
echo "  - Agents deployed to ~/.claude/agents/"
echo "  - MCP servers registered in ~/.claude.json"
if command -v claude &>/dev/null; then
echo "  - Plugins installed"
fi
echo "  - init-project-claude script at ~/.local/bin/"
echo "  - direnv .envrc files for work/personal directories"
echo "  - direnv hook in $SHELL_RC"
echo ""
echo "MCP servers:"
echo "  - jira-basis: Jira + Confluence (Atlassian)"
echo "  - redmine-onerhino: Redmine issue tracking"
echo "  - slack-onerhino: Slack (oneRhino workspace, OAuth)"
echo "  - slack-basis: Slack (Basis workspace, OAuth)"
echo "  - openbrowser: Browser automation (via plugin)"
if [[ -n "$CONTEXT7_KEY" ]]; then
echo "  - context7: Library documentation lookup"
fi
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: source $SHELL_RC)"
echo "  2. Restart Claude Code to load the new MCP servers"
echo "  3. In Claude Code, run /mcp to verify the servers are connected"
echo "  4. Use a Slack tool to trigger OAuth login for each Slack workspace"
echo "     (you'll be prompted to authenticate separately for slack-onerhino and slack-basis)"
