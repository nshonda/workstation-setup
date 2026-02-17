#!/usr/bin/env bash
set -euo pipefail

echo "--- macOS setup ---"

# Install dependencies via Homebrew
if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Install it from https://brew.sh"
    exit 1
fi

for pkg in gh cloudflared jq direnv; do
    if ! command -v "$pkg" &>/dev/null; then
        echo "Installing $pkg..."
        brew install "$pkg"
    else
        echo "$pkg already installed"
    fi
done

# gcloud — package name differs from binary name
if ! command -v gcloud &>/dev/null; then
    echo "Installing google-cloud-sdk..."
    brew install google-cloud-sdk
else
    echo "gcloud already installed"
fi

# Install RTK (Rust Token Killer) via cargo
if command -v cargo &>/dev/null; then
    if ! command -v rtk &>/dev/null; then
        echo "Installing rtk via cargo..."
        cargo install rtk
    else
        echo "rtk already installed"
    fi
else
    echo "cargo not found — skipping rtk install (install Rust from https://rustup.rs)"
fi

# Create workspace directories
mkdir -p ~/workstation/personal ~/workstation/work

echo "--- macOS setup done ---"
