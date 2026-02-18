#!/usr/bin/env bash
set -euo pipefail

echo "--- WSL/Linux setup ---"

# Install dependencies
sudo apt-get update -qq
for pkg in openssh-client git gh jq direnv libsecret-tools gnome-keyring dbus-x11; do
    if ! dpkg -s "$pkg" &>/dev/null 2>&1; then
        echo "Installing $pkg..."
        sudo apt-get install -y -qq "$pkg"
    else
        echo "$pkg already installed"
    fi
done

# gcloud — add Google's apt repo if needed, then install
if command -v gcloud &>/dev/null; then
    echo "gcloud already installed"
else
    echo "Installing google-cloud-cli..."
    if ! apt-cache show google-cloud-cli &>/dev/null 2>&1; then
        echo "Adding Google Cloud apt repo..."
        sudo apt-get install -y -qq apt-transport-https ca-certificates gnupg curl
        curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
        sudo apt-get update -qq
    fi
    sudo apt-get install -y -qq google-cloud-cli
    echo "gcloud installed — run 'gcloud auth login' to authenticate"
fi

# Line ending handling
git config --global core.autocrlf input

# RTK (Rust Token Killer) — install via official script (no Rust required)
if command -v rtk &>/dev/null; then
    echo "rtk already installed ($(rtk --version))"
else
    echo "Installing rtk..."
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
fi

# Create workspace directories
mkdir -p ~/workstation/personal ~/workstation/work

echo "--- WSL/Linux setup done ---"
