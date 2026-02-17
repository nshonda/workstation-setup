#!/usr/bin/env bash
set -euo pipefail

# Determine shell config file
if [ -f "$HOME/.zshrc" ]; then
    RC_FILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    RC_FILE="$HOME/.bashrc"
else
    RC_FILE="$HOME/.zshrc"
fi

MARKER="# workstation-setup commands"

# Remove old block if exists (to update)
if grep -qF "$MARKER" "$RC_FILE" 2>/dev/null; then
    # Remove from marker to next blank line or EOF
    sed -i.bak "/$MARKER/,/^$/d" "$RC_FILE"
    rm -f "$RC_FILE.bak"
fi

# Write marker line (expanded)
printf '\n%s\n' "$MARKER" >> "$RC_FILE"

# Write gh() wrapper (single-quoted heredoc — no expansion)
cat >> "$RC_FILE" <<'EOF'
# Auto-switch gh account based on directory
GH_PERSONAL="nshonda"
GH_WORK="natalihonda-basis"
gh() {
    local target="$GH_PERSONAL"
    if [[ "$PWD" == "$HOME/workstation/work"* ]]; then
        target="$GH_WORK"
    fi
    command gh auth switch --user "$target" 2>/dev/null || true
    command gh "$@"
}
EOF

echo "Commands installed in $RC_FILE:"
echo "  gh — Auto-switches GitHub account based on cwd (personal vs work)"
echo ""
echo "Run 'source $RC_FILE' or open a new terminal to use them."
