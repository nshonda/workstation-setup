# workstation-setup

Script-driven setup for multi-GitHub account development workstations. One command sets up SSH, git, GitHub CLI, and Claude Code across macOS and WSL/Linux.

## Quick Start

```bash
git clone git@github.com:nshonda/workstation-setup.git ~/workstation/personal/workstation-setup
cd ~/workstation/personal/workstation-setup
./setup.sh
```

## What It Does

1. **Dependencies** — installs gh, jq, direnv, cloudflared, RTK via brew (macOS) or apt (Linux)
2. **SSH** — generates keys for personal + work GitHub accounts with host aliases
3. **Git** — configures identity with conditional includes (work email for `~/workstation/work/`)
4. **GitHub CLI** — authenticates both accounts, installs auto-switch wrapper
5. **Claude Code** (optional) — deploys config, skills, hooks, MCP servers, plugins

## Repo Structure

- `scripts/` — setup scripts (all idempotent, safe to re-run)
- `claude/` — Claude Code configuration (deployed to `~/.claude/` by setup-claude.sh)
- `docs/` — reference documentation

## Re-running

All scripts are idempotent. Re-run `./setup.sh` or any individual script to update.
