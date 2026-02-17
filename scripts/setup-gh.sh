#!/usr/bin/env bash
set -euo pipefail

echo "--- GitHub CLI setup ---"

if ! command -v gh &>/dev/null; then
    echo "ERROR: gh not installed. Run setup-mac.sh or setup-wsl.sh first."
    exit 1
fi

echo ""
echo "Log in to your PERSONAL GitHub account first:"
echo "  (select SSH as preferred protocol)"
echo ""
gh auth login -h github.com

echo ""
echo "Now log in to your WORK GitHub account:"
echo "  (select SSH as preferred protocol)"
echo ""
gh auth login -h github.com

echo ""
echo "Accounts configured:"
gh auth status
echo ""
echo "The 'gh' wrapper in your shell will auto-switch accounts"
echo "based on whether you're in ~/workstation/work/ or not."
echo ""
echo "--- GitHub CLI setup done ---"
