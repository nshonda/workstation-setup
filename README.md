# workstation-setup

Script-driven setup for multi-GitHub account development workstations. One command sets up SSH, git, GitHub CLI, and Claude Code across macOS and WSL/Linux.

## Quick Start

```bash
git clone git@github.com:<YOUR_USERNAME>/workstation-setup.git ~/workstation/personal/workstation-setup
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

## References

### System Dependencies

| Tool | Purpose |
|------|---------|
| [GitHub CLI (`gh`)](https://cli.github.com/) | Multi-account GitHub auth + auto-switch wrapper |
| [direnv](https://direnv.net/) | Per-directory environment variables (tokens, credentials) |
| [jq](https://jqlang.github.io/jq/) | JSON processing for config merging |
| [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) | Cloudflare Tunnel client |
| [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) | GCS access for interactive plan uploads |
| [RTK](https://github.com/rtk-ai/rtk) | Token-optimized CLI proxy for Claude Code |
| [uv](https://docs.astral.sh/uv/) | Python package manager (used by MCP server wrappers) |

### MCP Servers

| Server | Purpose |
|--------|---------|
| [mcp-atlassian](https://github.com/sooperset/mcp-atlassian) | Jira + Confluence integration |
| [mcp-redmine](https://github.com/runekaagaard/mcp-redmine) | Redmine issue tracking |
| [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) | Browser automation, screenshots, performance profiling |
| [Context7](https://context7.com/) | Library/framework documentation lookup |

### Claude Code Plugins

| Plugin | Purpose |
|--------|---------|
| [claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | GitHub, Playwright, Supabase, code review, and more |
| [pro-workflow](https://github.com/rohitg00/pro-workflow) | Session management, learning capture, smart commits |

### Claude Code Skills (bundled)

| Skill | Source |
|-------|--------|
| research | 6-agent parallel deep research |
| interactive-plan | HTML architecture plans with Mermaid diagrams ([GCS setup](docs/gcs-setup.md)) |
| [web-design-guidelines](https://github.com/vercel-labs/web-interface-guidelines) | UI/accessibility audit |
| [next-best-practices](https://nextjs.org/docs) | Next.js file conventions, RSC, data patterns |
| [vercel-react-best-practices](https://vercel.com/blog) | React + Next.js performance optimization |
| [supabase-postgres-best-practices](https://supabase.com/docs/guides/database) | Postgres schema and query optimization |
| ss-dev | [SilverStripe](https://docs.silverstripe.org/) CMS development (SS3/4/5) |
| nuxt-dev | [Nuxt 3/4](https://nuxt.com/docs) framework conventions |
| wp-dev | [WordPress](https://developer.wordpress.org/) plugin/theme development |

### Additional Docs

- [SSH multi-account setup](docs/ssh-github-multi-account.md)
- [WSL setup](docs/wsl-setup.md)
- [GCS setup for interactive plans](docs/gcs-setup.md)
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code)
