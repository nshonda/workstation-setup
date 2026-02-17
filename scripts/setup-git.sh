#!/usr/bin/env bash
set -euo pipefail

echo "--- Git setup ---"

# Require identity env vars from setup.sh
: "${WS_FULL_NAME:?Set WS_FULL_NAME before running this script}"
: "${WS_PERSONAL_EMAIL:?Set WS_PERSONAL_EMAIL before running this script}"
: "${WS_WORK_EMAIL:?Set WS_WORK_EMAIL before running this script}"

# Global identity
git config --global user.name "$WS_FULL_NAME"
git config --global user.email "$WS_PERSONAL_EMAIL"

# Defaults
git config --global init.defaultBranch main
git config --global core.autocrlf input
git config --global pull.rebase false
git config --global push.default simple
git config --global push.followTags true
git config --global color.ui auto

# Work-specific gitconfig
cat > "$HOME/.gitconfig-basis" <<EOF
[user]
    name = ${WS_FULL_NAME}
    email = ${WS_WORK_EMAIL}
EOF

# Conditional includes for work repos (multiple possible locations)
git config --global --replace-all includeIf."gitdir:~/workstation/work/".path "~/.gitconfig-basis"
git config --global --add includeIf."gitdir:~/work/basis/".path "~/.gitconfig-basis"
git config --global --add includeIf."gitdir:~/Documents/basis/".path "~/.gitconfig-basis"

# Global gitignore
cat > "$HOME/.gitignore_global" <<'EOF'
.DS_Store
Thumbs.db
*.swp
*.swo
*~
.idea/
.vscode/
*.log
EOF
git config --global core.excludesFile "$HOME/.gitignore_global"

echo "--- Git setup done ---"
