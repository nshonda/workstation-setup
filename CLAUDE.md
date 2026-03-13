# CLAUDE.md

## Project Overview

Script-driven workstation setup for multi-GitHub account development. One config file (`config.env`), one command (`./setup.sh`) — consistent SSH keys, git identity, GitHub CLI auth, and Claude Code configuration across any machine.

## Key Commands

```bash
cp config.env.example config.env # Configure once
./setup.sh                      # Full setup
./scripts/setup-mac.sh          # macOS dependencies only
./scripts/setup-wsl.sh          # WSL/Linux dependencies only
./scripts/setup-shell.sh        # Shell env: zsh, OMZ, Spaceship, nvm, font
./scripts/setup-ssh.sh          # SSH keys for GitHub accounts
./scripts/setup-git.sh          # Git identity + conditional includes
./scripts/setup-gh.sh           # GitHub CLI multi-account auth
./scripts/setup-claude.sh       # Claude Code: MCP, config, skills, plugins
./scripts/sync-claude.sh        # Quick sync: config, hooks, skills, agents only
./scripts/install-commands.sh   # Shell gh() auto-switch wrapper
init-project-claude             # Bootstrap Claude Code for a project (--audit to scan, --audit --fix to auto-repair)
```

## Architecture

- **Workspace**: `~/workstation/{personal,work}/` — all repos live here
- **SSH**: Two RSA keys (personal GitHub, work GitHub) with host aliases
- **Git**: Conditional identity via `includeIf` — work email for `~/workstation/work/`
- **GitHub CLI**: `gh` auto-switches between personal and work accounts via shell wrapper
- **Shell**: zsh + Oh My Zsh + Spaceship theme + nvm + JetBrainsMono Nerd Font
- **Direnv**: Per-directory env vars — `GITHUB_TOKEN`, Jira/Redmine creds switch automatically
- **Claude Code**: Config, skills, hooks, agents deployed to `~/.claude/`; MCP servers registered in `~/.claude.json`

## Structure

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
  sync-claude.sh            # Quick sync: config, hooks, skills, agents only
  install-commands.sh       # gh auto-switch wrapper
  init-project-claude.sh   # Bootstrap Claude Code for a project (--audit to scan all)
claude/
  config/
    CLAUDE.md               # Global Claude instructions -> ~/.claude/CLAUDE.md
    RTK.md                  # RTK reference -> ~/.claude/RTK.md
    includes/
      skill-routing.md      # @include -> ~/.claude/includes/skill-routing.md
      subagent-rules.md     # @include -> ~/.claude/includes/subagent-rules.md
    settings.json           # Permissions, hooks, plugins -> ~/.claude/settings.json
    hookify.*.local.md      # Hookify rule files -> ~/.claude/
  skills/                   # All skills -> ~/.claude/skills/
  agents/                   # Subagent definitions -> ~/.claude/agents/
  hooks/
    strip-co-authored-by.sh  # Strip Co-Authored-By from git commands
    strip-attribution-mcp.sh # Strip self-attribution from MCP tool calls
    slack-schedule-rewrite.sh # Rewrite send_message -> schedule_message to avoid attribution
    validate-mcp-inputs.sh   # Validate MCP tool inputs before execution
    rtk-rewrite.sh           # Rewrite CLI commands through RTK proxy
    verify-before-commit.sh  # Block commit without passing tests/typecheck
    track-verification.sh    # Track successful test/typecheck runs
    guard-protected-branches.sh # Block commits/pushes on main/master
    context-monitor.js       # Context window usage warnings
    cross-project-memory.js  # Surface past learnings on session start
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
