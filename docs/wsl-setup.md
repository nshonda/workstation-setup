# WSL Setup Guide

## Install WSL2 + Ubuntu

In PowerShell (admin):

```powershell
wsl --install -d Ubuntu
```

Restart, then open Ubuntu from the Start menu and create your user.

## Run Setup

```bash
# Clone the repo inside WSL
git clone git@github.com:<YOUR_USERNAME>/workstation-setup.git ~/workstation/personal/workstation-setup
cd ~/workstation/personal/workstation-setup
./setup.sh
```

The setup script detects WSL/Linux automatically and:
- Installs gh, jq, direnv, openssh-client, git, google-cloud-cli via apt
- Installs credential management deps (libsecret-tools, gnome-keyring, dbus-x11)
- Sets `core.autocrlf input` to prevent line ending issues
- Installs RTK via install script (no Rust required)

## Claude Code in WSL

Install Claude Code inside WSL (not Windows):

```bash
npm install -g @anthropic-ai/claude-code
```

Run it from your WSL terminal. Your `~/workstation/` directory lives inside the WSL filesystem for best performance.

## Accessing WSL Files from Windows

WSL files are at `\\wsl$\Ubuntu\home\<user>\` in Windows Explorer, but avoid editing them from Windows — always work inside WSL for Git to work correctly.
