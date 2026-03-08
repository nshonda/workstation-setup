#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Workstation Setup ==="
echo ""

# ---------- Load config ----------

CONFIG_FILE="$REPO_DIR/config.env"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.env not found."
    echo "  cp config.env.example config.env"
    echo "  # Fill in your values, then re-run ./setup.sh"
    exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG_FILE"

# Validate required vars
for var in WS_FULL_NAME WS_PERSONAL_EMAIL WS_WORK_EMAIL WS_PERSONAL_GH_USER WS_WORK_GH_USER GH_PERSONAL_TOKEN GH_WORK_TOKEN; do
    if [[ -z "${!var:-}" ]]; then
        echo "Error: $var is required in config.env"
        exit 1
    fi
done

export WS_FULL_NAME WS_PERSONAL_EMAIL WS_WORK_EMAIL WS_PERSONAL_GH_USER WS_WORK_GH_USER

# Export optional vars for setup-claude.sh
export GH_PERSONAL_TOKEN="${GH_PERSONAL_TOKEN:-}"
export GH_WORK_TOKEN="${GH_WORK_TOKEN:-}"
export JIRA_URL="${JIRA_URL:-}"
export JIRA_EMAIL="${JIRA_EMAIL:-}"
export JIRA_TOKEN="${JIRA_TOKEN:-}"
export REDMINE_URL="${REDMINE_URL:-}"
export REDMINE_KEY="${REDMINE_KEY:-}"
export CONTEXT7_KEY="${CONTEXT7_KEY:-}"
export GCS_BUCKET="${GCS_BUCKET:-}"

echo "Config loaded: $CONFIG_FILE"
echo ""

# ---------- Platform setup ----------

case "$(uname -s)" in
    Darwin)
        echo "Detected: macOS"
        "$SCRIPT_DIR/setup-mac.sh"
        ;;
    Linux)
        echo "Detected: Linux/WSL"
        "$SCRIPT_DIR/setup-wsl.sh"
        ;;
    *)
        echo "Unsupported platform: $(uname -s)"
        exit 1
        ;;
esac

# Shell environment (zsh, plugins, font, .zshrc)
"$SCRIPT_DIR/setup-shell.sh"

# SSH + Git + GitHub CLI
"$SCRIPT_DIR/setup-ssh.sh"
"$SCRIPT_DIR/setup-git.sh"
"$SCRIPT_DIR/setup-gh.sh"

# Create workspace directories
mkdir -p ~/workstation/personal ~/workstation/work

# Shell commands (gh auto-switch wrapper)
"$SCRIPT_DIR/install-commands.sh"

# Claude Code setup
"$SCRIPT_DIR/setup-claude.sh"

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Add your SSH public keys to GitHub (printed above)"
echo "  2. Restart your terminal"
echo "  3. Verify: ssh -T git@github.com"
echo "  4. Verify: ssh -T git@github.com-${WS_WORK_GH_USER}"
