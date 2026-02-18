#!/usr/bin/env bash
set -euo pipefail

# Claude Code Setup
# Installs MCP servers, deploys config/skills/hooks, configures direnv + credentials

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_DIR="$REPO_DIR/claude"

echo "=== Claude Code Setup ==="
echo ""

# Require identity env vars from setup.sh
: "${WS_PERSONAL_GH_USER:?Set WS_PERSONAL_GH_USER before running this script}"
: "${WS_WORK_GH_USER:?Set WS_WORK_GH_USER before running this script}"

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

# ---------- 2. Prompt for credentials ----------

echo ""
echo "--- Credentials ---"
echo ""

echo "GitHub Personal Token (${WS_PERSONAL_GH_USER})"
echo "  Create at: https://github.com/settings/tokens"
read -sp "  Token: " GH_PERSONAL_TOKEN
echo ""

echo "GitHub Work Token (${WS_WORK_GH_USER})"
echo "  Create at: https://github.com/settings/tokens (work account)"
read -sp "  Token: " GH_WORK_TOKEN
echo ""

echo ""
echo "--- Jira Configuration ---"
read -p "Jira URL (e.g., company.atlassian.net): " JIRA_URL
JIRA_URL="${JIRA_URL#https://}"
JIRA_URL="${JIRA_URL#http://}"
JIRA_URL="${JIRA_URL%/}"
read -p "Jira email: " JIRA_EMAIL
echo "  Get your API token from: https://id.atlassian.com/manage-profile/security/api-tokens"
read -sp "Jira API token: " JIRA_TOKEN
echo ""

echo ""
echo "--- Redmine Configuration ---"
read -p "Redmine URL (e.g., redmine.example.com): " REDMINE_URL
REDMINE_URL="${REDMINE_URL#https://}"
REDMINE_URL="${REDMINE_URL#http://}"
REDMINE_URL="${REDMINE_URL%/}"
echo "  Get your API key from: Redmine > My Account > API access key"
read -sp "Redmine API key: " REDMINE_KEY
echo ""

echo ""
echo "--- Context7 Configuration ---"
echo "  Get your API key from: https://context7.com (sign up for free)"
read -sp "Context7 API key (or press Enter to skip): " CONTEXT7_KEY
echo ""

echo ""
echo "--- GCS Configuration ---"
read -p "GCS bucket for interactive plans (or press Enter to skip): " GCS_BUCKET

# ---------- 3. Store credentials in keychain ----------

echo ""
echo "--- Storing credentials ---"

if [[ "$PLATFORM" == "mac" ]]; then
    # Delete existing entries first
    security delete-generic-password -s "github-personal" -a "api-token" 2>/dev/null || true
    security delete-generic-password -s "github-work" -a "api-token" 2>/dev/null || true
    security delete-generic-password -s "jira-work" -a "api-token" 2>/dev/null || true
    security delete-generic-password -s "redmine-personal" -a "api-key" 2>/dev/null || true

    # Add new entries
    security add-generic-password -s "github-personal" -a "api-token" -w "$GH_PERSONAL_TOKEN"
    security add-generic-password -s "github-work" -a "api-token" -w "$GH_WORK_TOKEN"
    security add-generic-password -s "jira-work" -a "api-token" -w "$JIRA_TOKEN"
    security add-generic-password -s "redmine-personal" -a "api-key" -w "$REDMINE_KEY"
    echo "Credentials stored in macOS Keychain"
else
    if ! command -v secret-tool &>/dev/null; then
        echo "ERROR: secret-tool not found. Run setup-wsl.sh first to install keyring packages."
        exit 1
    fi
    # Start gnome-keyring daemon for this session
    if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
        eval "$(dbus-launch --sh-syntax)"
    fi
    eval "$(echo '' | gnome-keyring-daemon --unlock --components=secrets 2>/dev/null)" || true

    echo -n "$GH_PERSONAL_TOKEN" | secret-tool store --label="GitHub Personal Token" service github-personal username api-token
    echo -n "$GH_WORK_TOKEN" | secret-tool store --label="GitHub Work Token" service github-work username api-token
    echo -n "$JIRA_TOKEN" | secret-tool store --label="Jira Work API Token" service jira-work username api-token
    echo -n "$REDMINE_KEY" | secret-tool store --label="Redmine Personal API Key" service redmine-personal username api-key
    echo "Credentials stored in gnome-keyring"
fi

# ---------- 4. Create MCP wrapper scripts ----------

echo ""
echo "--- Creating MCP wrapper scripts ---"

mkdir -p ~/.local/bin

cat > ~/.local/bin/mcp-jira-wrapper << EOF
#!/bin/bash
# Wrapper script for mcp-atlassian that fetches credentials from keychain
export JIRA_URL="https://${JIRA_URL}"
export JIRA_USERNAME="${JIRA_EMAIL}"

if [[ "\$OSTYPE" == "darwin"* ]]; then
  export JIRA_API_TOKEN=\$(security find-generic-password -s "jira-work" -a "api-token" -w 2>/dev/null)
else
  export JIRA_API_TOKEN=\$(secret-tool lookup service jira-work username api-token 2>/dev/null)
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

cat > ~/.local/bin/mcp-redmine-wrapper << EOF
#!/bin/bash
# Wrapper script for mcp-redmine that fetches credentials from keychain
export REDMINE_URL="https://${REDMINE_URL}"
export REDMINE_ALLOWED_DIRECTORIES="\$HOME/workstation"

if [[ "\$OSTYPE" == "darwin"* ]]; then
  export REDMINE_API_KEY=\$(security find-generic-password -s "redmine-personal" -a "api-key" -w 2>/dev/null)
else
  export REDMINE_API_KEY=\$(secret-tool lookup service redmine-personal username api-key 2>/dev/null)
fi

if [ -z "\$REDMINE_API_KEY" ]; then
  echo "Error: Could not retrieve Redmine API key from keychain" >&2
  exit 1
fi

exec uvx --from mcp-redmine mcp-redmine "\$@"
EOF

chmod +x ~/.local/bin/mcp-jira-wrapper ~/.local/bin/mcp-redmine-wrapper
echo "Created ~/.local/bin/mcp-jira-wrapper"
echo "Created ~/.local/bin/mcp-redmine-wrapper"

# ---------- 5. Deploy Claude Code config ----------

echo ""
echo "--- Deploying Claude Code config ---"

mkdir -p ~/.claude/hooks ~/.claude/skills

# CLAUDE.md
if [[ -f "$CLAUDE_DIR/config/CLAUDE.md" ]]; then
    cp "$CLAUDE_DIR/config/CLAUDE.md" ~/.claude/CLAUDE.md
    echo "Deployed ~/.claude/CLAUDE.md"
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

# Hooks — copy all, chmod +x
if [[ -d "$CLAUDE_DIR/hooks" ]]; then
    cp -R "$CLAUDE_DIR/hooks/"* ~/.claude/hooks/ 2>/dev/null || true
    chmod +x ~/.claude/hooks/* 2>/dev/null || true
    echo "Deployed hooks to ~/.claude/hooks/"
fi

# ---------- 6. Register MCP servers in ~/.claude.json ----------

echo ""
echo "--- Configuring MCP servers ---"

CLAUDE_CONFIG=~/.claude.json

# Build MCP servers config
MCP_SERVERS='{
  "jira-work": {
    "type": "stdio",
    "command": "'"$HOME"'/.local/bin/mcp-jira-wrapper",
    "args": []
  },
  "redmine-personal": {
    "type": "stdio",
    "command": "'"$HOME"'/.local/bin/mcp-redmine-wrapper",
    "args": []
  },
  "chrome-devtools": {
    "type": "stdio",
    "command": "npx",
    "args": ["chrome-devtools-mcp@latest", "--isolated"],
    "env": {}
  }
}'

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
    claude plugins add rohitg00/pro-workflow 2>/dev/null || true
    echo "Plugins installed"
else
    echo "Claude Code CLI not found — install it first, then run:"
    echo "  claude plugins add anthropics/claude-plugins-official"
    echo "  claude plugins add rohitg00/pro-workflow"
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
  export JIRA_API_TOKEN=\$(security find-generic-password -s "jira-work" -a "api-token" -w 2>/dev/null)
else
  export GITHUB_TOKEN=\$(secret-tool lookup service github-work username api-token 2>/dev/null)
  export JIRA_API_TOKEN=\$(secret-tool lookup service jira-work username api-token 2>/dev/null)
fi

export JIRA_URL="https://${JIRA_URL}"
export JIRA_USERNAME="${JIRA_EMAIL}"

# GitHub MCP plugin expects GITHUB_PERSONAL_ACCESS_TOKEN
export GITHUB_PERSONAL_ACCESS_TOKEN="\$GITHUB_TOKEN"

# Unset personal service vars
unset REDMINE_URL
unset REDMINE_API_KEY
EOF

cat > ~/workstation/personal/.envrc << EOF
# Personal environment — GitHub + Redmine credentials
# Credentials fetched from keychain at directory entry

if [[ "\$OSTYPE" == "darwin"* ]]; then
  export GITHUB_TOKEN=\$(security find-generic-password -s "github-personal" -a "api-token" -w 2>/dev/null)
  export REDMINE_API_KEY=\$(security find-generic-password -s "redmine-personal" -a "api-key" -w 2>/dev/null)
else
  export GITHUB_TOKEN=\$(secret-tool lookup service github-personal username api-token 2>/dev/null)
  export REDMINE_API_KEY=\$(secret-tool lookup service redmine-personal username api-key 2>/dev/null)
fi

export REDMINE_URL="https://${REDMINE_URL}"

# GitHub MCP plugin expects GITHUB_PERSONAL_ACCESS_TOKEN
export GITHUB_PERSONAL_ACCESS_TOKEN="\$GITHUB_TOKEN"

# Unset work service vars
unset JIRA_URL
unset JIRA_USERNAME
unset JIRA_API_TOKEN
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
echo "  - MCP servers registered in ~/.claude.json"
if command -v claude &>/dev/null; then
echo "  - Plugins installed"
fi
echo "  - direnv .envrc files for work/personal directories"
echo "  - direnv hook in $SHELL_RC"
echo ""
echo "MCP servers:"
echo "  - jira-work: Jira + Confluence (Atlassian)"
echo "  - redmine-personal: Redmine issue tracking"
echo "  - chrome-devtools: Browser automation and debugging"
if [[ -n "$CONTEXT7_KEY" ]]; then
echo "  - context7: Library documentation lookup"
fi
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: source $SHELL_RC)"
echo "  2. Restart Claude Code to load the new MCP servers"
echo "  3. In Claude Code, run /mcp to verify the servers are connected"
