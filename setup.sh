#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/scripts" && pwd)"

echo "=== Workstation Setup ==="
echo ""

# Detect platform
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
echo "  4. Verify: ssh -T git@github.com-natalihonda-basis"
