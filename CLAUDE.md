# CLAUDE.md

## Project Overview

Script-driven workstation setup for multi-GitHub account development. Sets up SSH keys, git conditional identity, GitHub CLI multi-account auth, and Claude Code configuration (MCP servers, skills, hooks, plugins) — all from a single `setup.sh`.

## Key Commands

```bash
./setup.sh                      # Full setup (interactive)
./scripts/setup-mac.sh          # macOS dependencies only
./scripts/setup-wsl.sh          # WSL/Linux dependencies only
./scripts/setup-ssh.sh          # SSH keys for GitHub accounts
./scripts/setup-git.sh          # Git identity + conditional includes
./scripts/setup-gh.sh           # GitHub CLI multi-account auth
./scripts/setup-claude.sh       # Claude Code: MCP, config, skills, plugins
./scripts/install-commands.sh   # Shell gh() auto-switch wrapper
```

## Architecture

- **Workspace**: `~/workstation/{personal,work}/` — all repos live here
- **SSH**: Two RSA keys (personal GitHub, work GitHub) with host aliases
- **Git**: Conditional identity via `includeIf` — work email for `~/workstation/work/`
- **GitHub CLI**: `gh` auto-switches between personal and work accounts via shell wrapper
- **Direnv**: Per-directory env vars — `GITHUB_TOKEN`, Jira/Redmine creds switch automatically
- **Claude Code**: Config, skills, hooks deployed to `~/.claude/`; MCP servers registered in `~/.claude.json`

## Structure

```
setup.sh                    # Entry point
scripts/
  setup-mac.sh              # macOS deps (brew)
  setup-wsl.sh              # WSL/Linux deps (apt)
  setup-ssh.sh              # SSH keygen + config
  setup-git.sh              # Git identity + conditional includes
  setup-gh.sh               # GitHub CLI multi-account auth
  setup-claude.sh           # Claude Code setup (MCP, config, skills, plugins)
  install-commands.sh       # gh auto-switch wrapper
claude/
  config/
    CLAUDE.md               # Global Claude instructions -> ~/.claude/CLAUDE.md
    RTK.md                  # RTK reference -> ~/.claude/RTK.md
    settings.json           # Permissions, hooks, plugins -> ~/.claude/settings.json
  skills/                   # All skills -> ~/.claude/skills/
  hooks/                    # Hook scripts -> ~/.claude/hooks/
docs/
  ssh-github-multi-account.md
  wsl-setup.md
  gcs-setup.md
```

## Conventions

- Shell scripts in `scripts/`, all `set -euo pipefail`
- No build system, linting, or tests — pure shell automation
- Credentials stored in system credential store (macOS Keychain / gnome-keyring), never hardcoded
- `~/workstation/personal/` for personal repos, `~/workstation/work/` for work repos
