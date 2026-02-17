#!/usr/bin/env bash
set -euo pipefail

echo "--- Git setup ---"

# Global identity
git config --global user.name "Natali Honda"
git config --global user.email "natalihonda@gmail.com"

# Defaults
git config --global init.defaultBranch main
git config --global core.autocrlf input
git config --global pull.rebase false
git config --global push.default simple
git config --global push.followTags true
git config --global color.ui auto

# Work-specific gitconfig
cat > "$HOME/.gitconfig-basis" <<'EOF'
[user]
    name = Natali Honda
    email = natali.honda@basisworldwide.com
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
