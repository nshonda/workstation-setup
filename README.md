# workstation-setup

Script-driven setup for multi-GitHub account development workstations. One config file, one command — consistent SSH, git, GitHub CLI, and Claude Code across macOS and WSL/Linux. Fork it, fill in `config.env`, run `./setup.sh` on any new machine.

## Quick Start

```bash
git clone git@github.com:<YOUR_USERNAME>/workstation-setup.git ~/workstation/personal/workstation-setup
cd ~/workstation/personal/workstation-setup
cp config.env.example config.env
# Edit config.env with your values
./setup.sh
```

## Configuration

All configuration lives in `config.env` (gitignored). Copy the example and fill in your values:

| Variable | Required | Where to get it |
|----------|----------|-----------------|
| `WS_FULL_NAME` | Yes | Your name for git commits |
| `WS_PERSONAL_EMAIL` | Yes | Email for personal repos |
| `WS_WORK_EMAIL` | Yes | Email for work repos |
| `WS_PERSONAL_GH_USER` | Yes | Your personal GitHub username |
| `WS_WORK_GH_USER` | Yes | Your work GitHub username |
| `GH_PERSONAL_TOKEN` | Yes | [github.com/settings/tokens](https://github.com/settings/tokens) (personal account) |
| `GH_WORK_TOKEN` | Yes | [github.com/settings/tokens](https://github.com/settings/tokens) (work account) |
| `JIRA_URL` | No | e.g. `company.atlassian.net` — leave blank to skip |
| `JIRA_EMAIL` | No | Your Atlassian account email |
| `JIRA_TOKEN` | No | [Atlassian API tokens](https://id.atlassian.com/manage-profile/security/api-tokens) |
| `REDMINE_URL` | No | e.g. `redmine.example.com` — leave blank to skip |
| `REDMINE_KEY` | No | Redmine > My Account > API access key |
| `CONTEXT7_KEY` | No | [context7.com/dashboard](https://context7.com) > API Keys |
| `GCS_BUCKET` | No | See [GCS setup](docs/gcs-setup.md) |

Credentials are stored in the system keychain (macOS Keychain / gnome-keyring) on first run. The `config.env` file is only read at setup time.

## What It Does

1. **Dependencies** — installs gh, jq, direnv, gcloud, RTK via brew (macOS) or apt (Linux); cloudflared on macOS only
2. **SSH** — generates keys for personal + work GitHub accounts with host aliases
3. **Git** — configures identity with conditional includes (work email for `~/workstation/work/`)
4. **GitHub CLI** — authenticates both accounts, installs auto-switch wrapper
5. **Claude Code** — deploys a full AI coding assistant config: MCP servers, skills, hooks, plugins, agents, and behavioral guardrails. See [Claude Code setup docs](docs/claude-code.md) for the full breakdown.

## Repo Structure

```
config.env.example          # Configuration template (cp to config.env)
setup.sh                    # Entry point
scripts/
  setup-mac.sh              # macOS deps (brew)
  setup-wsl.sh              # WSL/Linux deps (apt)
  setup-shell.sh            # Shell env (zsh, OMZ, Spaceship, nvm, font)
  setup-ssh.sh              # SSH keygen + config
  setup-git.sh              # Git identity + conditional includes
  setup-gh.sh               # GitHub CLI multi-account auth
  setup-claude.sh           # Claude Code setup (MCP, config, skills, plugins)
  install-commands.sh        # gh auto-switch wrapper
  init-project-claude.sh   # Bootstrap Claude Code for a project (--audit to scan, --audit --fix to auto-repair)
claude/                     # Claude Code config source (deployed to ~/.claude/)
  config/                   # CLAUDE.md, settings.json, hookify rules
  skills/                   # Slash commands (22 skills)
  agents/                   # Specialist subagents (architect-reviewer, mcp-developer)
  hooks/                    # PreToolUse/PostToolUse/SessionStart scripts (8 hooks)
docs/
  claude-code.md            # Claude Code setup architecture and reference
  ssh-github-multi-account.md
  wsl-setup.md
  gcs-setup.md
```

## Re-running

All scripts are idempotent. Re-run `./setup.sh` or any individual script to update.

## System Dependencies

| Tool | Purpose |
|------|---------|
| [GitHub CLI (`gh`)](https://cli.github.com/) | Multi-account GitHub auth + auto-switch wrapper |
| [direnv](https://direnv.net/) | Per-directory environment variables (tokens, credentials) |
| [jq](https://jqlang.github.io/jq/) | JSON processing for config merging |
| [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) | Cloudflare Tunnel client |
| [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) | GCS access for interactive plan uploads |
| [RTK](https://github.com/rtk-ai/rtk) | Token-optimized CLI proxy for Claude Code |
| [uv](https://docs.astral.sh/uv/) | Python package manager (used by MCP server wrappers) |

## Docs

- [Claude Code setup](docs/claude-code.md) — architecture, MCP servers, hooks, skills, plugins, agents, permissions
- [SSH multi-account setup](docs/ssh-github-multi-account.md)
- [WSL setup](docs/wsl-setup.md)
- [GCS setup for interactive plans](docs/gcs-setup.md)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
