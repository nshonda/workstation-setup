#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"

echo "=== Workstation Setup ==="
echo ""

# ---------- Collect identity info ----------

echo "--- Identity ---"
echo ""

read -p "Full name: " WS_FULL_NAME
read -p "Personal email: " WS_PERSONAL_EMAIL
read -p "Work email: " WS_WORK_EMAIL
read -p "Personal GitHub username: " WS_PERSONAL_GH_USER
read -p "Work GitHub username: " WS_WORK_GH_USER

[[ -n "$WS_FULL_NAME" ]]         || { echo "Error: Full name is required."; exit 1; }
[[ -n "$WS_PERSONAL_EMAIL" ]]    || { echo "Error: Personal email is required."; exit 1; }
[[ -n "$WS_WORK_EMAIL" ]]        || { echo "Error: Work email is required."; exit 1; }
[[ -n "$WS_PERSONAL_GH_USER" ]]  || { echo "Error: Personal GitHub username is required."; exit 1; }
[[ -n "$WS_WORK_GH_USER" ]]      || { echo "Error: Work GitHub username is required."; exit 1; }

export WS_FULL_NAME WS_PERSONAL_EMAIL WS_WORK_EMAIL WS_PERSONAL_GH_USER WS_WORK_GH_USER

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

# SSH + Git + GitHub CLI
"$SCRIPT_DIR/setup-ssh.sh"
"$SCRIPT_DIR/setup-git.sh"
"$SCRIPT_DIR/setup-gh.sh"

# Create workspace directories
mkdir -p ~/workstation/personal ~/workstation/work

# Shell commands (gh auto-switch wrapper)
"$SCRIPT_DIR/install-commands.sh"

# Claude Code setup (optional)
echo ""
read -p "Set up Claude Code (MCP servers, config, skills, plugins)? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    "$SCRIPT_DIR/setup-claude.sh"
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "Next steps:"
echo "  1. Add your SSH public keys to GitHub (printed above)"
echo "  2. Restart your terminal"
echo "  3. Verify: ssh -T git@github.com"
echo "  4. Verify: ssh -T git@github.com-${WS_WORK_GH_USER}"
