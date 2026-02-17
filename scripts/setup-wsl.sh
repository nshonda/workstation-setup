#!/usr/bin/env bash
set -euo pipefail

echo "--- WSL/Linux setup ---"

# Install dependencies
sudo apt-get update -qq
for pkg in openssh-client git gh jq direnv; do
    if ! dpkg -s "$pkg" &>/dev/null 2>&1; then
        echo "Installing $pkg..."
        sudo apt-get install -y -qq "$pkg"
    else
        echo "$pkg already installed"
    fi
done

# Line ending handling
git config --global core.autocrlf input

# RTK (Rust Token Killer) — requires cargo
if command -v rtk &>/dev/null; then
    echo "rtk already installed"
elif command -v cargo &>/dev/null; then
    echo "Installing rtk via cargo..."
    cargo install rtk
else
    echo "cargo not found — skipping rtk install (install Rust from https://rustup.rs)"
fi

# Create workspace directories
mkdir -p ~/workstation/personal ~/workstation/work

echo "--- WSL/Linux setup done ---"
